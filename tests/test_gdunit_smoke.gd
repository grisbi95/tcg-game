extends GdUnitTestSuite
## Vérifie que GdUnit4 6.2.1 fonctionne en headless avec Godot 4.7.2 (décision 0001).


func test_framework_runs() -> void:
	assert_int(1 + 1).is_equal(2)
