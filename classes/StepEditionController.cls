public with sharing class StepEditionController {
    public final String STEP_TYPE_USERS = 'Users';
    public Settings settings { get; set; }

    /**
     * main component object
     */
    public Step__c step;
    public Boolean scalableGrid { get; set; }

    /* faster render definer */
    public String stepType { get; set; }

    /* helper to create inputText */
    public String inputAux { get; set; }
    public AuxiliaryObject__c lookupAux { get; set; }

    /* shows if from Org has filter activated */
    public Boolean filtered { get; set; }

    /**
     * config helper for UI components for step type.
     */
    public Map<String, Map<String, Object>> completeUITypeConfig = new Map<String, Map<String, Object>>{
        'Users' => new Map<String, Object>{ 'renderForm' => true, 'renderGrid' => true, 'renderQueryBuilder' => false },
        'MetaData' => new Map<String, Object>{ 'renderForm' => false, 'renderGrid' => true, 'renderQueryBuilder' => false },
        'Full Profiles' => new Map<String, Object>{ 'renderForm' => false, 'renderGrid' => true, 'renderQueryBuilder' => false }
    };

    public Map<String, Object> configUI { get; set; }

    /**
     * setter should be defined in commponents
     * to call fake constructor for UI
     */
    public void setStep(Step__c s) {
        this.step = s;
        this.stepType = s.Type__c;
        //init UI config.
        initConfig();
    }

    public Step__c getStep() {
        return this.step;
    }

    public StepEditionController() {
        //initConfig();
        settings = new Settings();
        scalableGrid = Settings.scalableGrid;
    }

    public void initConfig() {
        configUI = completeUITypeConfig.get(this.stepType);

        //TODO
        filtered = true;
    }

    public Boolean getIsFeatureAvailable() {
        return true;
    }

    public String getFlowsAvailableForExecution() {
        return DeploymentStepsUtils.getFlowsAvailableForExecution();
    }

    public void validateDataTemplateDeployment() {
        String stepId = ApexPages.currentPage().getParameters().get('stepId');
        if (String.isNotBlank(stepId) && stepId instanceof Id) {
            DataStepValidator validator = new DataStepValidator((Id) stepId);
            validator.validate();
        }
    }
}