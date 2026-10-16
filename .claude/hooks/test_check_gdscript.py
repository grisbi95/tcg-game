"""Tests du hook, isolés du jeu et sans dépendance tierce."""
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('check_gdscript', Path(__file__).with_name('check_gdscript.py'))
hook = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hook)


class HookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='hook test ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        (self.root / 'project.godot').write_text('config_version=5\n')
        self.script = self.root / 'scripts with spaces' / 'card.gd'
        self.script.parent.mkdir()
        self.script.write_text('extends RefCounted\n')
        self.calls = []

    def run_hook(self, path=None, diagnostic='', code=0, version='4.7.2.stable.official.test', raw=None, tool='Edit', cli=None, failure=None):
        payload = {'hook_event_name':'PostToolUse', 'tool_name':tool, 'cwd':str(self.root),
                   'tool_input':{'file_path':str(path or self.script)}}
        def run(command, **kwargs):
            self.calls.append((command, kwargs))
            if failure:
                raise failure
            output = version if '--version' in command else diagnostic
            return subprocess.CompletedProcess(command, 0 if '--version' in command else code, output, '')
        argv = ['check_gdscript.py'] + ([] if cli is None else cli)
        stderr, stdout = io.StringIO(), io.StringIO()
        with patch.object(hook, '__file__', str(self.root / '.claude/hooks/check_gdscript.py')), \
             patch.object(hook.sys, 'argv', argv), patch.object(hook.sys, 'stdin', io.StringIO(raw if raw is not None else json.dumps(payload))), \
             patch.object(hook.sys, 'stderr', stderr), patch.object(hook.sys, 'stdout', stdout), \
             patch.object(hook, 'godot_binary', return_value='godot'), patch.object(hook.subprocess, 'run', side_effect=run):
            result = hook.main()
        return result, stdout.getvalue(), stderr.getvalue()

    def test_success_with_spaces_and_no_shell(self):
        code, out, err = self.run_hook()
        self.assertEqual(code, 0, err)
        self.assertEqual(json.loads(out)['hookSpecificOutput']['hookEventName'], 'PostToolUse')
        command, options = self.calls[-1]
        self.assertIn('res://scripts with spaces/card.gd', command)
        self.assertNotIn('shell', options)
        self.assertIn('--check-only', command)

    def test_write_and_multiedit(self):
        for tool in ('Write', 'MultiEdit'):
            with self.subTest(tool=tool):
                self.assertEqual(self.run_hook(tool=tool)[0], 0)

    def test_script_error_even_with_zero_exit(self):
        self.assertEqual(self.run_hook(diagnostic='SCRIPT ERROR: Parse Error: broken')[0], 2)

    def test_warning_even_with_zero_exit(self):
        self.assertEqual(self.run_hook(diagnostic='WARNING: diagnostic')[0], 2)

    def test_nonzero_exit(self):
        self.assertEqual(self.run_hook(code=1)[0], 2)

    def test_bad_version(self):
        self.assertEqual(self.run_hook(version='4.6.stable.test')[0], 2)

    def test_unavailable_engine(self):
        self.assertEqual(self.run_hook(failure=FileNotFoundError('godot'))[0], 2)

    def test_timeout(self):
        self.assertEqual(self.run_hook(failure=subprocess.TimeoutExpired('godot', 30))[0], 2)

    def test_invalid_payload(self):
        for raw in ('{', '[]', '{"hook_event_name":"PostToolUse","tool_name":"Edit"}'):
            with self.subTest(raw=raw):
                self.assertEqual(self.run_hook(raw=raw)[0], 2)

    def test_non_gd_and_other_tool_skipped(self):
        self.assertEqual(self.run_hook(path=self.root/'README.md')[0], 0)
        self.assertEqual(self.run_hook(tool='Read')[0], 0)
        self.assertEqual(self.calls, [])

    def test_protected_dirs_skipped(self):
        for name in ('addons', '.godot'):
            with self.subTest(name=name):
                self.assertEqual(self.run_hook(path=self.root/name/'skip.gd')[0], 0)
        self.assertEqual(self.calls, [])

    def test_external_and_missing_paths(self):
        self.assertEqual(self.run_hook(path=self.root.parent/'outside.gd')[0], 2)
        self.assertEqual(self.run_hook(path=self.root/'missing.gd')[0], 2)

    def test_symlink_outside_rejected(self):
        link = self.root / 'link.gd'
        link.symlink_to(self.root.parent/'outside.gd')
        self.assertEqual(self.run_hook(path=link)[0], 2)

    def test_cli_and_argument_count(self):
        self.assertEqual(self.run_hook(cli=['res://scripts with spaces/card.gd'])[0], 0)
        self.assertEqual(self.run_hook(cli=['a.gd', '--editor'])[0], 2)


if __name__ == '__main__':
    unittest.main()
