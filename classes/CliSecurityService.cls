public with sharing class CliSecurityService {
    /**
     * It is used the check validity of current user for desired operation
     * @return null if it's Valid
     */
    public static String checkValidity() {
        if(!FeatureHelper.isChangeChangeManagementEnabled()) {
            return Label.FEATURE_NOT_SUPPORTED;
        }
        if(!LicenseHelper.actionIsLicenseEnabled('commitFiles')) {
            return Label.CCM_License_Restriction;
        }
        return null;
    }

    /**
     * This method checks OLS for queries.
     * @param sObjectList a list of SObjects to check
     * @return list of non accesible objcts
     */
    public static List<String> checkOLS(List<String> sObjectList) {
        List<String> noAccessList = new List<String>();
        for(Schema.DescribeSObjectResult res : Schema.describeSObjects(sObjectList)) {
            if(!res.isQueryable() && !res.isAccessible()) {
                noAccessList.add(res.getLabel());
            }
        }
        return noAccessList;
    }

    /**
     * This method checks OLS for queries.
     * @param sObjectString SObjects to check
     * @param sObjectFieldsList list of fields.
     * @param modifier Utilities.DML_Action  (INS, UPD, UPS  ENUM class)
     * @return list of non accesible fields.
     */
    public static List<String> checkFLS(String sObjectString, List<String> sObjectFieldsList, Utilities.DML_Action modifier) {
        List<String> noAccessList = new List<String>();
        Map<String, Schema.SObjectField> sObjectFieldsMap = Schema.getGlobalDescribe().get(sObjectString).getDescribe().fields.getMap();
        for(String fieldName : sObjectFieldsList) {
            if(sObjectFieldsMap.containsKey(fieldName)) {
                if((modifier == Utilities.DML_Action.INS || modifier == Utilities.DML_Action.UPS) && !sObjectFieldsMap.get(fieldName).getDescribe().isCreateable()) {
                    noAccessList.add(fieldName);
                } else if((modifier == Utilities.DML_Action.UPD || modifier == Utilities.DML_Action.UPS) && !sObjectFieldsMap.get(fieldName).getDescribe().isUpdateable()) {
                    noAccessList.add(fieldName);
                }
            }
        }
        return noAccessList;
    }
}