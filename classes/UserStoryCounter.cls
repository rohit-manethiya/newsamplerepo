/**
 * TODO: create a new and isolated Test class for this one. Currently it is using TestGlobalUtilities
 * for time saving purposes since behaviour can be asserted there as well.
 */
global with sharing class UserStoryCounter {
    global class InvocableVariables {
        @InvocableVariable(label='Type (Ahead / Behind)' required=true)
        global String type;
        @InvocableVariable(label='Pipeline Id' required=true)
        global Id pipelineId;
        @InvocableVariable(label='Environment Id' required=true)
        global Id environmentId;
    }

    /**
     * Invocable method to allow users retrieve the number of User Stories ahead or behind for an environment in a pipeline.
     * @param  variables InvocableVariables
     * @return List<Integer>
     * @see InvocableVariable
     * @see InvocableMethod
     * @WARNING method may not behave as expected if one source environment is connected to two destinations in the same pipeline
     */
    @InvocableMethod(
        label='Get User Story Count'
        description='Gets the number of user stories ahead or behind (based on the provided type parameter), for the given pipeline and environment'
    )
    global static List<Integer> getUserStoryCount(List<InvocableVariables> variables) {
        InvocableVariables variable = variables[0];
        Deployment_Flow_Step__c pipelineConnection = [
            SELECT Destination_Environment__c, Deployment_Flow__c, Source_Environment__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :variable.pipelineId AND Source_Environment__c = :variable.environmentId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        switch on variable.type.toUpperCase() {
            when 'AHEAD' {
                return new List<Integer>{ GlobalUtilities.getUserStoriesAhead(pipelineConnection).size() };
            }
            when 'BEHIND' {
                return new List<Integer>{ GlobalUtilities.getUserStoriesBehind(pipelineConnection).size() };
            }
            when else {
                return null;
            }
        }
    }
}