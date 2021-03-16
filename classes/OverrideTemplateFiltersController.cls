public with sharing class OverrideTemplateFiltersController {

    public String deploymentId { get; set; }
    public String stepId { get; set; }
    
    public OverrideTemplateFiltersController() {
        Map<String, String> pageParams = ApexPages.currentPage().getParameters();
        deploymentId = pageParams.get('deploymentId');
        stepId = pageParams.get('stepId');
    }
}