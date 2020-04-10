/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class LookupRollupHelper_Test {
	
	 static testMethod void testNullValues() {
	 	TestDataGenerator_LookupRollupSummary dataGenerator = new TestDataGenerator_LookupRollupSummary();    	
    	//Initialize the Configuration Object    
    	dataGenerator.getRollupConfiguration();
    	dataGenerator.getContacts(true);
		//Pass in the name of the child record, in this case 'Contact' and the name of the parent record, in this case 'Account';	
		LookupRollupHelper lh = new LookupRollupHelper( 'Contact', 'Account');
		
		//Test errors
		System.assertEquals(null,lh.queryForChildren(null,null,null,null,null,null,null));		 
		
		//want to pass a null result list
		List<Account> accounts = dataGenerator.getAccounts(false);
		for(Account a : accounts) {
			a.NumberOfEmployees = 1000;
		}
		lh.assignRollupResults(null, (List<sObject>)accounts);		
		for(Account a : accounts) {
			System.assertEquals(0,a.NumberOfEmployees);
		}
		
		//Test errors		
		System.assertEquals(null,lh.getCurrentConfig(null,null,null));
	 }

    static testMethod void testLookups() {
    
    	TestDataGenerator_LookupRollupSummary dataGenerator = new TestDataGenerator_LookupRollupSummary();    	
    	//Initialize the Configuration Object    
    	dataGenerator.getRollupConfiguration();
    	
		//Pass in the name of the child record, in this case 'Contact' and the name of the parent record, in this case 'Account';	
		LookupRollupHelper lh = new LookupRollupHelper( 'Contact', 'Account');
		
		//Convert the Trigger.list to a list of sObjects
		lh.rollupSummary((List<sObject>)dataGenerator.getContacts(true), null);
		
		System.assert(dataGenerator.getContacts(false).size() > 0, 'No Contacts');
		System.assert(dataGenerator.getAccounts(false).size() > 0, 'No Accounts');
		System.assert(dataGenerator.getContacts(false)[0].Id != null,'Null Id');
		System.assert(dataGenerator.getContacts(false)[0].AccountId != null, 'Null AccountId');
		System.assert(dataGenerator.getAccounts(false)[0].Id != null, 'Null Id');
		
		//How many contacts per account are there?
		Map<Id,Integer> accountIdToContactCount = new Map<Id,Integer>();
		
		for(Contact c : dataGenerator.getContacts(false)) {
			Integer counter = 0;			
			if(c.AccountId != null) {
				if(accountIdToContactCount.containsKey(c.AccountId)) {
					counter = accountIdToContactCount.get(c.AccountId);
				}
				counter++;				
				accountIdToContactCount.put(c.AccountId,counter);
			}
		}
				
		//Now make sure that the Account.Description contains the count of Contacts
		List<Account> accounts = [SELECT Id, NumberOfEmployees FROM Account WHERE Id IN :accountIdToContactCount.keySet()];
		
		System.assert(accounts != null && accounts.size() > 0, 'No Accounts: ' + accountIdToContactCount.keySet());
		for(Account account : accounts) {
			Integer contactCount = (account.NumberOfEmployees != null) ? Integer.valueOf(account.NumberOfEmployees) : 0;
			System.assert(accountIdToContactCount.get(account.Id) > 0,'Count is 0');
			System.assert(accountIdToContactCount.get(account.Id) == contactCount, 'Expected: ' + accountIdToContactCount.get(account.Id) + ' got ' + account.NumberOfEmployees);
		}		
    }
}