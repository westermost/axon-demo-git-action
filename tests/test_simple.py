def test_simple():
    """Simple test that always passes"""
    assert 1 + 1 == 2

def test_hello():
    """Test string"""
    assert "hello".upper() == "HELLO"

def test_math():
    """Test math operations"""
    assert 5 * 5 == 25
    assert 10 - 3 == 7

def test_list():
    """Test list operations"""
    my_list = [1, 2, 3, 4, 5]
    assert len(my_list) == 5
    assert sum(my_list) == 15
    assert my_list[0] == 1
