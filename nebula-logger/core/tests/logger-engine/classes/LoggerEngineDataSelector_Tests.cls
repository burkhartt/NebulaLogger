//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerEngineDataSelector_Tests {
    @IsTest
    static void it_loads_mock_instance() {
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        System.assertNotEquals(mockSelector, LoggerEngineDataSelector.getInstance());

        LoggerEngineDataSelector.setMock(mockSelector);

        System.assertEquals(mockSelector, LoggerEngineDataSelector.getInstance());
    }

    @IsTest
    static void it_returns_cached_auth_session() {
        List<AuthSession> sessions = [
            SELECT
                Id,
                LoginType,
                LoginHistoryId,
                LoginHistory.Application,
                LoginHistory.Browser,
                LoginHistory.Platform,
                LogoutUrl,
                SessionSecurityLevel,
                SessionType,
                SourceIp
            FROM AuthSession
            WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = TRUE AND ParentId = NULL
        ];
        AuthSession expectedAuthSession = sessions.isEmpty() ? null : sessions.get(0);
        System.assertEquals(1, Limits.getQueries());

        AuthSession returnedAuthSession = LoggerEngineDataSelector.getInstance().getCachedAuthSession();

        System.assertEquals(2, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedAuthSession();
        System.assertEquals(2, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedAuthSession, returnedAuthSession);
    }

    @IsTest
    static void it_does_not_query_auth_session_when_disabled_via_logger_parameter() {
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.assertEquals(mockSelector, LoggerEngineDataSelector.getInstance());
        System.assertEquals(0, mockSelector.getCachedAuthSessionQueryCount());
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionData', Value__c = String.valueOf(false)));

        AuthSession returnedAuthSession = LoggerEngineDataSelector.getInstance().getCachedAuthSession();

        System.assertEquals(0, mockSelector.getCachedAuthSessionQueryCount());
        System.assertEquals(null, returnedAuthSession);
    }

    @IsTest
    static void it_returns_cached_sobject_handlers() {
        List<LoggerSObjectHandler__mdt> expectedSObjectHandlers = [
            SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName, SObjectTypeOverride__c
            FROM LoggerSObjectHandler__mdt
            WHERE IsEnabled__c = TRUE
        ];
        System.assertEquals(0, Limits.getQueries());

        List<LoggerSObjectHandler__mdt> returnedSObjectHandlers = LoggerEngineDataSelector.getInstance().getCachedLoggerSObjectHandlers();

        // The specific query used for LoggerSObjectHandler__mdt shouldn't count towards the SOQL query limits,
        // so 0 queries are expected here
        System.assertEquals(0, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedLoggerSObjectHandlers();
        System.assertEquals(0, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedSObjectHandlers, returnedSObjectHandlers);
    }

    @IsTest
    static void it_returns_cached_organization() {
        Organization expectedOrganization = [
            SELECT Id, InstanceName, IsSandbox, Name, NamespacePrefix, OrganizationType, TrialExpirationDate
            FROM Organization
        ];
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.assertEquals(mockSelector, LoggerEngineDataSelector.getInstance());
        System.assertEquals(0, mockSelector.getCachedOrganizationQueryCount());

        Organization returnedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();

        System.assertEquals(1, mockSelector.getCachedOrganizationQueryCount());
        LoggerEngineDataSelector.getInstance().getCachedOrganization();
        System.assertEquals(1, mockSelector.getCachedOrganizationQueryCount(), 'Query results should have been cached');
        System.assertEquals(expectedOrganization, returnedOrganization);
    }

    @IsTest
    static void it_does_not_query_organization_when_disabled_via_logger_parameter() {
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        System.assertNotEquals(mockSelector, LoggerEngineDataSelector.getInstance());
        System.assertEquals(0, mockSelector.getCachedOrganizationQueryCount());
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationData', Value__c = String.valueOf(false)));

        Organization returnedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();

        System.assertEquals(0, mockSelector.getCachedOrganizationQueryCount());
        System.assertEquals(null, returnedOrganization);
    }

    @IsTest
    static void it_returns_cached_tag_assignment_rules() {
        List<LogEntryTagRule__mdt> expectedTagAssignmentRules = [
            SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
            FROM LogEntryTagRule__mdt
            WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
        ];
        System.assertEquals(1, Limits.getQueries());

        List<LogEntryTagRule__mdt> returnedTagAssignmentRules = LoggerEngineDataSelector.getInstance().getCachedTagAssignmentRules();

        System.assertEquals(2, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedTagAssignmentRules();
        System.assertEquals(2, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedTagAssignmentRules, returnedTagAssignmentRules);
    }

    @IsTest
    static void it_returns_cached_user() {
        User expectedUser = [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        System.assertEquals(1, Limits.getQueries());

        User returnedUser = LoggerEngineDataSelector.getInstance().getCachedUser();

        System.assertEquals(2, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedUser();
        System.assertEquals(2, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedUser, returnedUser);
    }

    private class MockLoggerEngineDataSelector extends LoggerEngineDataSelector {
        private Integer authSessionQueryCount = 0;
        private Integer organizationQueryCount = 0;

        public override AuthSession getCachedAuthSession() {
            Integer originalQueryCount = Limits.getQueries();
            AuthSession result = super.getCachedAuthSession();
            if (Limits.getQueries() != originalQueryCount) {
                authSessionQueryCount = Limits.getQueries() - originalQueryCount;
            }
            return result;
        }

        public Integer getCachedAuthSessionQueryCount() {
            return authSessionQueryCount;
        }

        public override Organization getCachedOrganization() {
            Integer originalQueryCount = Limits.getQueries();
            Organization result = super.getCachedOrganization();
            if (Limits.getQueries() != originalQueryCount) {
                organizationQueryCount = Limits.getQueries() - originalQueryCount;
            }
            return result;
        }

        public Integer getCachedOrganizationQueryCount() {
            return organizationQueryCount;
        }
    }
}
