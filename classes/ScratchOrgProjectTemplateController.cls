/**
 * Created by ferhatozsavran on 2/22/18.
 */

public with sharing class ScratchOrgProjectTemplateController extends ScratchOrgWizardPageBase {
    public String componentMode {get; set;}
    public ScratchOrgProjectTemplateController(ApexPages.StandardController std) {
        componentMode =  std.getId() != null ? 'editStd' : 'template';
    }
}