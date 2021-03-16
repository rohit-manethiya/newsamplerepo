/**
 * REST Service for Handshaking and dispatching the CodeScan_Token to our backend
 * This will help implement security toward this token
 * @author Alberto Ojedo
 * @version 1.0
 * @since Copado v11
 */
@RestResource(urlMapping='/CodeScanHandshake')
global with sharing class CodeScanHandshakeService {
    @HttpGet
    global static List<CodeScanResponse> handshakeAndReturnEncryptedToken() {
        List<CodeScanResponse> arrayResponse = new List<CodeScanResponse>();
        CodeScanResponse csResp = new CodeScanResponse();
        RestRequest req = RestContext.request;

        //Parse backend params
        String staticCodeAnalysisSettingsId = req.params.get('settingsId');

        if (!CodeScanHandshakeService.handshakeCheck(req.headers.get('handshakeId'))) {
            //If no handshake, we return Insufficient Privileges
            return serviceResponse('1', Label.Insufficient_Access_Rights);
        }

        //If handshake is good, we deliver the CodeScan Token
        List<Sensitive_Information__c> sensitiveInformations = [
            SELECT API_Token__c
            FROM Sensitive_Information__c
            WHERE Name = :staticCodeAnalysisSettingsId
        ];

        if (!sensitiveInformations.isEmpty()) {
            return serviceResponse('0', DeployAPI.encryptAPIKey(sensitiveInformations[0].API_Token__c));
        } else {
            //Settings not found, return an error
            return serviceResponse('1', Label.UNABLE_TO_FIND_SCA_SETTING_RECORD);
        }
    }

    private static List<CodeScanResponse> serviceResponse(String errorCode, String message) {
        List<CodeScanResponse> arrayResponse = new List<CodeScanResponse>();
        CodeScanResponse csResp = new CodeScanResponse();
        csResp.errorCode = errorCode;
        csResp.message = message;
        arrayResponse.add(csResp);
        return arrayResponse;
    }

    public static Boolean handshakeCheck(String backendToken) {
        return !String.isEmpty(backendToken) && DeployAPI.getAuthToken() == DeployAPI.decryptAPIKey(backendToken);
    }

    global with sharing class CodeScanResponse {
        global String errorCode { get; set; }
        global String message { get; set; }
    }
}