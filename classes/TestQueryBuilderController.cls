@isTest
private class TestQueryBuilderController {
    static testMethod void doTest(){
        queryBuilderController con = new queryBuilderController();
        con.errorLevel = 'WARNING';
        con.messageName = 'warning message';
        con.showMessage();
        system.assert(testMethodUtilities.hasMessage('warning message'));
        
        con.errorLevel = 'CONFIRM';
        con.messageName = 'confirm message';
        con.showMessage();
        system.assert(testMethodUtilities.hasMessage('confirm message'));
    }
}