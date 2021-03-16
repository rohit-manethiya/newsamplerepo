/**
 * Created by mertyalti on 19/01/2018.
 */

public with sharing class ScratchOrgDefinitionController extends ScratchOrgWizardPageBase{
    public String componentMode {get; set;}
    public ScratchOrgDefinitionController(ApexPages.StandardController std) {
        componentMode = ApexPages.currentPage().getUrl().contains('clone') ? 'cloneStd' : std.getId() != null ? 'editStd' : 'newStd';
    }
}