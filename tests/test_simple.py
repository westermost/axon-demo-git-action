import allure

@allure.feature('Calculator')
@allure.story('Basic Math')
@allure.severity(allure.severity_level.CRITICAL)
def test_simple():
    """Simple test that always passes"""
    with allure.step('Add 1 + 1'):
        result = 1 + 1
        allure.attach(str(result), name='Result', attachment_type=allure.attachment_type.TEXT)
        assert result == 2

@allure.feature('String Operations')
@allure.story('Text Processing')
def test_hello():
    """Test string"""
    with allure.step('Convert to uppercase'):
        result = "hello".upper()
        assert result == "HELLO"
