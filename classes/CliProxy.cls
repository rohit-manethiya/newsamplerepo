@RestResource(urlMapping='/clioperations/*')
global with sharing class CliProxy {
    private static final Map<String, Type> serviceLayerMap = new Map<String, Type>{
            'work:set' => WorkSetService.class,
            'work:display' => WorkDisplayService.class,
            'work:submit' => WorkSubmitService.class,
            'work:push' => WorkPushService.class
    };

    private static CLIInterface cliInterface;

    @HttpPost
    global static String doPost() {
        String validity = CliSecurityService.checkValidity();
        if(String.isNotBlank(validity)) {
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), validity));
        }

        RestRequest req = RestContext.request;
        System.debug('req==> ' + req);

        CLIWrapper request = (CLIWrapper) JSON.deserialize(req.requestBody.toString(), CLIWrapper.class);
        System.debug('request==> ' + request);
        cliInterface = initializeService(request);
        if(null == cliInterface) {
            return JSON.serialize(new CliSfDataWrapper(CliSfDataWrapper.StatusResult.ERROR.name(), Label.UnSupportedOperation));
        }

        return cliInterface.run(request);
    }

    /**
     * Strategy pattern
     * Different services will be initialised by using CLIInterface based on requested root
     * @see CLIInterface
     */
    private static CLIInterface initializeService(CLIWrapper request) {
        if(serviceLayerMap.containsKey(request.mainService + ':' + request.subService)) {
            return (CLIInterface) (serviceLayerMap.get(request.mainService + ':' + request.subService).newInstance());
        } else {
            return null;
        }
    }

    /**
     * Wrapper class to deserialize JSON coming from CLI calls
     */
    public class CLIWrapper {
        public String mainService;
        public String subService;
        public String operation;
        public String body;
    }
}