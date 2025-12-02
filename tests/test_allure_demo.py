import pytest
import allure
import requests

@allure.feature('Calculator')
@allure.story('Basic Operations')
@allure.severity(allure.severity_level.CRITICAL)
def test_addition_with_allure():
    """Test addition with Allure"""
    with allure.step('Add 2 + 3'):
        result = 2 + 3
        allure.attach(str(result), name='Result', attachment_type=allure.attachment_type.TEXT)
        assert result == 5

@allure.feature('String Operations')
@allure.story('Text Processing')
def test_string_with_allure():
    """Test string operations"""
    text = "Hello World"
    
    with allure.step(f'Convert "{text}" to uppercase'):
        upper = text.upper()
        assert upper == "HELLO WORLD"
    
    with allure.step('Split text'):
        words = text.split()
        assert len(words) == 2

@allure.feature('API Testing')
@allure.story('HTTP Requests')
@allure.severity(allure.severity_level.NORMAL)
def test_api_request():
    """Test API request"""
    with allure.step('Send GET request'):
        response = requests.get('https://httpbin.org/get')
        allure.attach(str(response.status_code), name='Status Code', attachment_type=allure.attachment_type.TEXT)
        assert response.status_code == 200
    
    with allure.step('Verify response'):
        data = response.json()
        assert 'url' in data

@allure.feature('Data Structures')
@allure.story('List Operations')
def test_list_with_allure():
    """Test list operations"""
    with allure.step('Create list'):
        my_list = [1, 2, 3, 4, 5]
        allure.attach(str(my_list), name='List', attachment_type=allure.attachment_type.TEXT)
    
    with allure.step('Calculate sum'):
        total = sum(my_list)
        assert total == 15
