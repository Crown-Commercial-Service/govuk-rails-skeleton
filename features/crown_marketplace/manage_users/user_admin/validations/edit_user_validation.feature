Feature: Manage users - User admin - Edit user - Validations

  Background: Navigate to the user show page
    Given I sign in as an 'super admin' user go to the crown marketplace dashboard
    When I click on 'Manage users'
    Then I am on the 'Manage users' page
    Given I am going to do a search to find users
    And I search for 'service_admin@test.com' and there is a user with the following details:
      | Account enabled         | true          |
      | Confirmation status     | confirmed     |
      | Mobile telephone number | 07987654321   |
      | MFA enabled             | true          |
      | Roles                   | ccs_employee  | 
      | Service access          | mc_access     |
    And I enter 'service_admin@test.com' into the search
    And I click on 'Search'
    Then I should see the following users in the results:
      | service_admin@test.com  | Enabled   |
    And I view the user with email 'service_admin@test.com'
    Then I am on the 'View user' page
    And I can manage the user
    And the user has the following details:
      | Email address           | service_admin@test.com  |
      | Account status          | Enabled                 |
      | Confirmation status     | confirmed               |
      | Mobile telephone number | 07987654321             |
      | MFA status              | Enabled                 |
      | Roles                   | Service admin           |
      | Service access          | Management Consultancy  |

  Scenario: Telephone number - Validations
    And I change the 'Mobile telephone number' for the user
    And I am on the 'Update user mobile telephone number' page
    And I enter the following details into the form:
      | Mobile telephone number | <telephone_number>  |
    And I click on 'Save and return'
    Then I should see the following error messages:
      | <error_message> |

    Examples:
      | telephone_number  | error_message                                               |
      |                   | Enter a UK mobile telephone number, for example 07700900982 |
      | 0712345678        | Enter a UK mobile telephone number, for example 07700900982 |
      | 01702123456       | Enter a UK mobile telephone number, for example 07700900982 |

  Scenario: Service access - Validations
    And I change the 'Service access' for the user
    And I am on the 'Update user service access' page
    And I deselect the following items:
      | Management Consultancy |
    And I click on 'Save and return'
    Then I should see the following error messages:
      | You must select the service access for the user from this list |

  Scenario: Service error
    And I change the 'Service access' for the user
    And I am on the 'Update user service access' page
    And I cannot update the user account because of an error
    And I click on 'Save and return'
    Then I should see the following error messages:
      | An error occured when trying to update the user |
