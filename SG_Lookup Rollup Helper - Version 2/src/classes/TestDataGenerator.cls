public with sharing class TestDataGenerator {
	
	public static Account getAccount() {
        Account a = new Account();
        a.Name = 'Test';
        a.BillingCity = 'Austin';
        a.BillingCountry = 'US';
        a.BillingState = 'TX';
        a.BillingPostalCode = '78731';
        
        a.ShippingCity = 'Austin';
        a.ShippingCountry = 'US';
        a.ShippingState = 'TX';
        a.ShippingPostalCode = '78731';

        return a;
    } 
    
    public static Account getAccountAndInsert() {
        Account a = getAccount();
        insert a;
        return a;
    }
    
    public static Contact getContact(Account a) {
		Contact c = new Contact();
		c.AccountId = a.Id;
		c.FirstName = 'First';
		c.LastName = 'Last';
		c.Email = 'Test@TestNowhere.com';
		//c.Cost__c = 5;
		//c.Hours_Spent__c = 5;
		System.debug('getContact: returning ' + c);
		return c;
	}

	public static Contact getContactAndInsert(Account a) {
		Contact c = getContact(a);
		insert c;
		return c;
	}
	
	public static List<Contact> getNContactsAndInsert( Account a, Integer numberOfChildren )
    {
        List<Contact> children = new List<Contact>();
        for ( Integer i = 0; i < numberOfChildren; i++ )
        {
            Contact pt = getContact( a );
            children.add( pt );
        }
        insert children;
        return children;
    }

}