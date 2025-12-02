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
