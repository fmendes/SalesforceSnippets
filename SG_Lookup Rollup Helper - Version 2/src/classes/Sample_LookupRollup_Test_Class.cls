@isTest
private class Sample_LookupRollup_Test_Class {

   /* TODO: Use Find/Replace to change every instance of Contact with the real child object */
	/* TODO: Use Find/Replace to change every instance of Account with the real parent object */
	/* TODO: Update the correct fields */
	
	/*
		* Test for finding parent; finding field to summarize
		* Test for batches 
	*/
	
    static testMethod void testLookups()  
    {
    	TestDataGenerator_LookupRollupSummary dataGenerator = new TestDataGenerator_LookupRollupSummary();  
    	dataGenerator.accountNum = 1;
    	dataGenerator.contactNum = 1;
    	
    	List<Account> accounts = dataGenerator.getAccounts(true);
    	List<Contact> contacts = dataGenerator.getContacts(false);
    	for ( Contact c : contacts )
    	{
    		c.AccountId = accounts[0].Id;
    	}  
    	insert contacts;
    	
    	Account parent = accounts[0];
    	Contact child = contacts[0];	
    	
    	// parent rollups are stored in fields, "Total_Cost__c" and "Total_Hours__c" 
    	// child values are stored in fields, "Cost__c" and "Hours_Spent__c" 
    	
    	System.debug('Test Parent: ' + parent );
    	Set<Id> parentIds = new Set<Id>();
    	parentIds.add( parent.Id );
    	List<Account> parentList = getParents( parentIds );
    	parent = parentList[0];
    	System.debug('Test Parent after fetch: ' + parent );
    	
    	System.assertEquals( child.Cost__c, parent.Total_Cost__c );
    	System.assertEquals( child.Hours_Spent__c, parent.Total_Hours__c );
    	
    }
    
    static testMethod void testDeleteLookups() 
    {
    	TestDataGenerator_LookupRollupSummary dataGenerator = new TestDataGenerator_LookupRollupSummary();  
    	dataGenerator.accountNum = 1;
    	dataGenerator.contactNum = 1;
    	
    	List<Account> accounts = dataGenerator.getAccounts(true);
    	List<Contact> contacts = dataGenerator.getContacts(false);
    	for ( Contact c : contacts )
    	{
    		c.AccountId = accounts[0].Id;
    	}  
    	insert contacts;
    	
    	Account parent = accounts[0];
    	Contact child = contacts[0];
    	
    	// parent rollups are stored in fields, "Total_Cost__c" and "Total_Hours__c"
    	// child values are stored in fields, "Cost__c" and "Hours_Spent__c"
    	
    	System.debug('Test Parent: ' + parent );
    	Set<Id> parentIds = new Set<Id>();
    	parentIds.add( parent.Id );
    	List<Account> parentList = getParents( parentIds );
    	parent = parentList[0];
    	System.debug('Test Parent after fetch: ' + parent );
    	
    	System.assertEquals( child.Cost__c, parent.Total_Cost__c );
    	System.assertEquals( child.Hours_Spent__c, parent.Total_Hours__c );
    	
    	Double newParentCost = parent.Total_Cost__c - child.Cost__c;
    	Double newParentHours = parent.Total_Hours__c - child.Hours_Spent__c;
    	System.debug('parent hours after delete should be: (cost, hours): ' + newParentCost + ', ' + newParentHours);
    	
    	delete child;
    	parentList = getParents( parentIds );
    	parent = parentList[0];
    	System.debug('parent hours after delete really are: (cost, hours): ' + parent.Total_Cost__c + ', ' + parent.Total_Hours__c);
    	System.assertEquals( parent.Total_Cost__c, newParentCost );
    	System.assertEquals( parent.Total_Hours__c, newParentHours );
    	
    }
    
    static testMethod void testBatchLookups() 
    {
    	// test out batchable
    	
    	TestDataGenerator_LookupRollupSummary dataGenerator = new TestDataGenerator_LookupRollupSummary();  
    	dataGenerator.accountNum = 20;
    	dataGenerator.contactNum = 100;
    	
    	List<Account> parentList = dataGenerator.getAccounts(true);
    	List<Contact> childList = dataGenerator.getContacts(true);
    	
    	Set<Id> parentIds = new Set<Id>();
    	Set<Id> childIds = new Set<Id>();
    	
    	Test.startTest();
    	Map<Id, Double> totalHourMap = new Map<Id, Double>();
    	Map<Id, Double> totalCostMap = new Map<Id, Double>();
    	
    	for ( Contact child : childList )
    	{
    		parentIds.add( child.AccountId );
    		childIds.add( child.Id );
    		
    		Double hourCount = 0;
    		Double costCount = 0;
    		
    		Double currentHourCount = totalHourMap.get( child.AccountId );
    		if ( currentHourCount == null ) currentHourCount = 0;
    		
    		Double currentCostCount = totalCostMap.get( child.AccountId );
    		if ( currentCostCount == null ) currentCostCount = 0;
    		
    		hourCount = currentHourCount + child.Hours_Spent__c;
    		costCount = currentCostCount + child.Cost__c;
    		
    		totalHourMap.put( child.AccountId, hourCount );
    		totalCostMap.put( child.AccountId, costCount );   
    			
    	}
    	// get refreshed data
    	parentList = getParents( parentIds );
    	childList = getChildren( childIds );  
    	
    	// test the rollups...
    	for ( Account parent : parentList )
    	{
    		Double hours = totalHourMap.get( parent.Id );
    		Double cost = totalCostMap.get( parent.Id );
    		
    		System.assertEquals( parent.Total_Hours__c, hours );
    		System.assertEquals( parent.Total_Cost__c, cost );
    	} 	    	
    	Test.stopTest();
    }
    
	static List<Account> getParents( Set<Id> parentIds )
    {
    	List<Account> parentList = [SELECT id, name, total_cost__c, total_hours__c FROM Account WHERE Id IN :parentIds];
    	return parentList;
    }
    
    static List<Contact> getChildren( Set<Id> childIds )
    {
    	List<Contact> childList = [SELECT id, name, AccountId, cost__c, hours_spent__c FROM Contact WHERE Id IN :childIds ];
    	return childList;
    }    
    
}