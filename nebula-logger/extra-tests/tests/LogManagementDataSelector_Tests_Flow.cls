//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=false)
private class LogManagementDataSelector_Tests_Flow {
    private static final String TEST_FLOW_NAME = 'MockLogBatchPurgerPlugin';

    @IsTest
    static void it_returns_matching_flow_definition_view_for_specified_flow_api_name() {
        List<String> targetFlowApiNames = new List<String>{ TEST_FLOW_NAME };
        List<FlowDefinitionView> expectedResults = [
            SELECT ActiveVersionId, ApiName, Description, DurableId, Label, LastModifiedBy, LastModifiedDate, ManageableState, ProcessType, TriggerType
            FROM FlowDefinitionView
            WHERE ApiName IN :targetFlowApiNames AND IsActive = TRUE
        ];

        List<FlowDefinitionView> returnedResults = LogManagementDataSelector.getInstance().getFlowDefinitionViewsByFlowApiName(targetFlowApiNames);

        System.assertEquals(expectedResults, returnedResults);
    }

    @IsTest
    static void it_does_not_query_flow_definition_views_when_disabled_via_logger_parameter() {
        List<String> targetFlowApiNames = new List<String>{ TEST_FLOW_NAME };
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryFlowDefinitionViewData', Value__c = String.valueOf(false)));
        System.assertEquals(false, LoggerParameter.QUERY_FLOW_DEFINITION_VIEW_DATA);
        Integer originalQueryCount = Limits.getQueries();

        List<FlowDefinitionView> returnedResults = LogManagementDataSelector.getInstance().getFlowDefinitionViewsByFlowApiName(targetFlowApiNames);

        System.assertEquals(originalQueryCount, Limits.getQueries());
        System.assertEquals(0, returnedResults.size());
    }
}
