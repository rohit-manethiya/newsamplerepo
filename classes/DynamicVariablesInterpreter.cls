public with sharing class DynamicVariablesInterpreter {
    private static Deployment_Job__c deploymentJob;

    @TestVisible
    private static final String currentUserApiKey {
        get {
            if (currentUserApiKey == null) {
                final Personal_Settings__c currentUserPersonalSettings = Personal_Settings__c.getInstance();
                final String currentUserEncryptedApiKey = currentUserPersonalSettings.API_Key__c;
                final Blob encryptedApiKey = EncodingUtil.base64Decode(currentUserEncryptedApiKey);
                final Settings__c orgDefaultSettings = Settings__c.getOrgDefaults();
                final String orgCryptoKey = orgDefaultSettings.CryptoKey__c;
                final Blob keyToUseToDecrypt = EncodingUtil.base64Decode(orgCryptoKey);
                final String decryptedCurrentUserApiKey = Crypto.decryptWithManagedIV('AES256', keyToUseToDecrypt, encryptedApiKey).toString();
                currentUserApiKey = decryptedCurrentUserApiKey;
            }
            return currentUserApiKey;
        }
        set;
    }

    private static final Map<String, DynamicVariableInterpreter> dynamicVariableInterpretersByExpectedDynamicVariableValue = new Map<String, DynamicVariableInterpreter>{
        '{!CopadoOrg.OrgId}' => new CopadoOrgOrgId(),
        '{!CopadoOrg.CredentialId}' => new CopadoOrgCredentialId(),
        '{!CopadoOrg.ApiKey}' => new CopadoOrgApiKey(),
        '{!Source.OrgId}' => new SourceOrgId(),
        '{!Source.CredentialId}' => new SourceCredentialId(),
        '{!Destination.OrgId}' => new DestinationOrgId(),
        '{!Destination.CredentialId}' => new DestinationCredentialId(),
        '{!Deployment.Id}' => new DeploymentId(),
        '{!Deployment.JobId}' => new DeploymentJobId(),
        '{!Promotion.Id}' => new PromotionId(),
        '{!ResumeURL}' => new ResumeURL()
    };

    public static Map<String, Object> getDynamicVariablesInterpreted(
        final Deployment_Job__c currentDeploymentJob,
        final Map<String, Object> parameterValuesByName
    ) {
        deploymentJob = currentDeploymentJob;
        for (String parameterName : parameterValuesByName.keySet()) {
            final String parameterValue;
            try {
                parameterValue = (String) parameterValuesByName.get(parameterName);
                if (dynamicVariableInterpretersByExpectedDynamicVariableValue.containsKey(parameterValue)) {
                    final DynamicVariableInterpreter specificDynamicVariableInterpreter = dynamicVariableInterpretersByExpectedDynamicVariableValue.get(
                        parameterValue
                    );
                    final Object interpretedValue = specificDynamicVariableInterpreter.getInterpretedValue();
                    parameterValuesByName.put(parameterName, interpretedValue);
                }
            } catch (final System.TypeException e) {
                System.debug('Skipped silently, parameter is not of String type.');
            }
        }
        return parameterValuesByName;
    }

    /**
     * Class names of implementations should follow the same convention so code could be replaced by this at anytime:
     * final String dynamicVariableClassNameFromParameterValue = parameterValue.remove('{').remove('!').remove('.').remove('}');
     * final Type dynamicVariableInterpreterSpecificType = Type.forName('DynamicVariablesInterpreter.' + dynamicVariableClassNameFromParameterValue);
     * final DynamicVariableInterpreter specificDynamicVariableInterpreter = (DynamicVariableInterpreter) dynamicVariableInterpreterSpecificType.newInstance();
     * NOTE: In moder API versions, Type.forName can apparently only access public or global members, regardless of test context or @TestVisible being present
     */
    private interface DynamicVariableInterpreter {
        Object getInterpretedValue();
    }

    private class CopadoOrgOrgId implements DynamicVariableInterpreter {
        public Id getInterpretedValue() {
            return UserInfo.getOrganizationId();
        }
    }

    private class CopadoOrgCredentialId implements DynamicVariableInterpreter {
        public Id getInterpretedValue() {
            final String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
            // Possible exception is not handled for this query since it should really never happen and, if it does,
            // then certainly it should throw an exception (that would mean that the user has not an authenticated
            // org credential for the Copado org, and hence, he should have not reached this logic as part of in any page)
            final Org__c copadoOrgCredential = [
                SELECT Id
                FROM Org__c
                WHERE Validated_Date__c != null AND SFDC_Org_ID__c = :sfdcOrgId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            return copadoOrgCredential.Id;
        }
    }

    private class CopadoOrgApiKey implements DynamicVariableInterpreter {
        public String getInterpretedValue() {
            return currentUserApiKey;
        }
    }

    private class SourceOrgId implements DynamicVariableInterpreter {
        public String getInterpretedValue() {
            return deploymentJob.Step__r.Deployment__r.From_Org__r.Environment__r.Org_ID__c;
        }
    }

    private class SourceCredentialId implements DynamicVariableInterpreter {
        public Id getInterpretedValue() {
            return deploymentJob.Step__r.Deployment__r.From_Org__r.Id;
        }
    }

    private class DestinationOrgId implements DynamicVariableInterpreter {
        public String getInterpretedValue() {
            return deploymentJob.Destination_Org__r.To_Org__r.Environment__r.Org_ID__c;
        }
    }

    private class DestinationCredentialId implements DynamicVariableInterpreter {
        public Id getInterpretedValue() {
            return deploymentJob.Destination_Org__r.To_Org__r.Id;
        }
    }

    private class DeploymentId implements DynamicVariableInterpreter {
        public Id getInterpretedValue() {
            return deploymentJob.Step__r.Deployment__r.Id;
        }
    }

    private class DeploymentJobId implements DynamicVariableInterpreter {
        public Id getInterpretedValue() {
            return deploymentJob.Id;
        }
    }

    private class PromotionId implements DynamicVariableInterpreter {
        public Id getInterpretedValue() {
            return deploymentJob.Step__r.Deployment__r.Promotion__c;
        }
    }

    private class ResumeURL implements DynamicVariableInterpreter {
        public String getInterpretedValue() {
            return Settings.server_url +
                '/json/v1/webhook/resumeDeployment/' +
                EncodingUtil.urlEncode(deploymentJob.Id, 'UTF-8') +
                '?api_key=' +
                EncodingUtil.urlEncode(currentUserApiKey, 'UTF-8') +
                '&deploymentId=' +
                EncodingUtil.urlEncode(deploymentJob.Step__r.Deployment__r.Id, 'UTF-8');
        }
    }
}