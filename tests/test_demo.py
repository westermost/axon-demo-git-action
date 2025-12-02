import pytest

def test_addition():
    """Test basic addition"""
    assert 1 + 1 == 2
    assert 5 + 3 == 8

def test_subtraction():
    """Test basic subtraction"""
    assert 10 - 5 == 5
    assert 100 - 1 == 99

def test_string_operations():
    """Test string operations"""
    assert "hello".upper() == "HELLO"
    assert "WORLD".lower() == "world"
    assert "hello world".split() == ["hello", "world"]

def test_list_operations():
    """Test list operations"""
    my_list = [1, 2, 3, 4, 5]
    assert len(my_list) == 5
    assert sum(my_list) == 15

@pytest.mark.parametrize("input,expected", [
    (2, 4),
    (3, 9),
    (4, 16),
    (5, 25),
])
def test_square(input, expected):
    """Test square function"""
    assert input ** 2 == expected
