public with sharing class queryBuilderController {

    public String errorLevel {get; set;}
    public String messageName {get; set;}

    public void showMessage() {
        ApexPages.Severity level = ApexPages.Severity.ERROR;
        if(errorLevel == 'WARNING') {
            level = ApexPages.Severity.Warning;
        }else{
            if(errorLevel == 'CONFIRM') {
                level = ApexPages.Severity.CONFIRM;
            }
        }
        ApexPages.addMessage(new ApexPages.Message(level, messageName));
        
    }

    public void clearMessage(){
        ApexPages.getMessages().clear();
    }
    

}