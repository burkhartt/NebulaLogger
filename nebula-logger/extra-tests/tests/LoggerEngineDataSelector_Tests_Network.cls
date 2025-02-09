//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerEngineDataSelector_Tests_Network {
    private static final String EXPERIENCE_CLOUD_GUEST_PROFILE_NAME = 'Logger Test Site Guest Profile';
    private static final String EXPERIENCE_CLOUD_NETWORK_NAME = 'Logger Test Site';
    private static final String GUEST_USER_TYPE = 'Guest';
    private static final String LOG_CREATOR_PERMISSION_SET_NAME = 'LoggerLogCreator';

    @IsTest
    static void it_returns_cached_network() {
        if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        Id expectedNetworkId = (Id) getExperienceCloudNetwork().get('Id');
        System.assertEquals(1, Limits.getQueries());
        Integer expectedQueryCount = Limits.getQueries() + 1;

        SObject returnedNetworkSite = LoggerEngineDataSelector.getInstance().getCachedNetwork(expectedNetworkId);

        System.assertEquals(expectedQueryCount, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedNetwork(expectedNetworkId);
        System.assertEquals(expectedQueryCount, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedNetworkId, returnedNetworkSite?.Id);
    }

    static SObject getExperienceCloudNetwork() {
        return Database.query('SELECT Id, Name, UrlPathPrefix FROM Network WHERE Name = :EXPERIENCE_CLOUD_NETWORK_NAME');
    }
}
