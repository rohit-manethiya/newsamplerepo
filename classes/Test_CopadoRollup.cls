@isTest
public class Test_CopadoRollup {
    public static testMethod void myUnitTest() {
        List<Account> accList = new List<Account>();
        for (integer i = 0; i < 10; i++) {
            Account acc = new Account(
                    Name = 'Test Account' + i
            );
            accList.add(acc);
        }
        insert accList;
        List<Contact> conList = new List<Contact>();
        for (integer j = 0; j < accList.size(); j++) {
            Contact con = new Contact(
                    AccountId = accList[j].id,
                    LastName = 'Test Con' + j
            );
            conList.add(con);
        }
        insert conList;

        CopadoRollup.RollUpContext ctx = new CopadoRollup.RollUpContext(
                Account.SobjectType,
                Contact.SobjectType,
                Schema.SObjectType.Contact.fields.AccountId
        );

        ctx.add(
                new CopadoRollup.RollupSummaryField(
                        Schema.SObjectType.Account.fields.NumberOfEmployees,
                        Schema.SObjectType.Contact.fields.Name,
                        CopadoRollup.OperationEnum.Count
                )
        );
        List<Contact > detailsList = new List<Contact >([SELECT Id,Name,AccountId FROM Contact WHERE Id IN :conList]);
        system.debug('detailsList ===>' + detailsList);
        Sobject[] masters = CopadoRollup.rollUp(ctx, detailsList);
        system.debug('masters===>' + masters);
        update masters;
    }
}