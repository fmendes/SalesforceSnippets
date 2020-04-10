public without sharing class TestDataGenerator_LookupRollupSummary {

	//Always allow for the creation of one or more users
	private List<User> users;
	private Map<String,List<User>> profileToUserMap;	
	private List<Account> accounts;
	private List<Contact> contacts;
	
	private RollupConfigs__c config;
	
	public Integer accountNum;
	public Integer contactNum;
	public Integer userNum;
	
	public TestDataGenerator_LookupRollupSummary(){
		userNum = 2;
		accountNum = 2;
		contactNum = 6;
	}
	
	public RollupConfigs__c getRollupConfiguration() {
		if(config == null) {
			List<RollupConfigs__c> existingContactAccountConfig = [SELECT Id 
																   FROM RollupConfigs__c 
																   WHERE Child_Object_Name__c = 'Contact' 
																   AND Parent_Object__c = 'Account'];
			if(existingContactAccountConfig != null && existingContactAccountConfig.size() == 1) {
				config = existingContactAccountConfig[0];
			} else {
				config = new RollupConfigs__c();
			}
			config.Child_Object_Name__c = 'Contact';
			config.Parent_Object__c = 'Account';
			config.Name = 'ContactToAccount';
			config.parentRowCount__c = 'NumberOfEmployees';
			config.queryField_parentRelationshipName__c = 'AccountId';
			config.queryField1__c = null;
			config.queryField2__c = null;
			config.queryField3__c = null;
			config.queryField4__c = null;
			config.queryField5__c = null;
			config.parentQueryField1__c = null;
			config.parentQueryField2__c = null;
			config.parentQueryField3__c = null;
			config.parentQueryField4__c = null;
			config.parentQueryField5__c = null;			
			
			if(config.Id == null) {
				insert config;
			} else {
				update config;
			}
		}
		return config;
	}
	
	public Map<String,List<User>> getProfileToUserMap(List<String> profileNames) {
		System.debug('*** getProfileToUserMap');
		getUsers(profileNames);
		return profileToUserMap;
	}
	
	//A user need a profile
	public List<User> getUsers(List<String> profileNames){
		System.debug('*** getUsers');
		if(users == null) {
			users = new List<User>();
			
			//There are 3 classes of users, create at least one of each
			if(profileNames == null || profileNames.size() == 0) {
				profileNames = new List<String>();
				profileNames.add('Standard User');		
			}
			
			System.debug('*** profileNames: ' + profileNames);
			
			Map<Id,Profile> profileMap;			
			try {		
				profileMap = new Map<Id,Profile>([select id, Name from profile where name IN :profileNames]);
			} catch (Exception exp) {
				//Can not test exceptions
				System.debug('*** Could not find profiles: ' + exp.getMessage());				
			}
			
			if(profileMap == null || profileMap.size() == 0) {
				profileMap = new Map<Id,Profile>([select id, Name from profile where name = 'Standard User']);
			}
			
			System.debug('*** profileMap: ' + profileMap);
			
			//Untested - this should never happen, just 3x checking
			if(profileMap == null || profileMap.size() == 0) {
				System.assert(false,'Could not find profiles');
				return null;
			}
									
			if(userNum == null || userNum < profileMap.size()) {
				userNum = profileMap.size();
			}
					
			for(Integer i = 0; i < userNum; i++) {
				Integer profilePosition = Math.mod(i,profileMap.size());
				Integer random = Math.random().intValue();
				User u = getUser(profileMap.values()[profilePosition], 'User' + i.format() + random.format());
				users.add(u);						
			}
			
			System.debug('*** inserting users');
			insert users;
			
			//Now build the user map
			profileToUserMap = new Map<String,List<User>>();
			
			for(User u : users) {
				if(profileToUserMap.containsKey(profileMap.get(u.ProfileId).Name)) {
					profileToUserMap.get(profileMap.get(u.ProfileId).Name).add(u);
				} else {
					List<User> tmpUsers = new List<User>();
					tmpUsers.add(u);
					profileToUserMap.put(profileMap.get(u.ProfileId).Name,tmpUsers);
				}
			}
		}		
		return users;
	}
	
	private User getUser(Profile p, String uniqueName){
		System.debug('*** getUser');
				
		String orgId = (String)Userinfo.getOrganizationId();		
		String uniqueEmail = uniqueName + '@' + orgId + '.net.test';
		
		User u = new User(alias = 'standt', 
						  email=uniqueEmail,
		                  emailencodingkey='UTF-8', 
		                  lastname='Testing', 
		                  languagelocalekey='en_US',
		                  localesidkey='en_US', 
		                  profileid = p.Id,
						  timezonesidkey='America/Los_Angeles',
						  username=uniqueEmail);
		return u;
	}

		
	public List<Account> getAccounts(Boolean xCommit) {
		if(accounts == null) {
			accounts = new List<Account>();
			for(Integer i = 0; i < accountNum; i++) {
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
				a.NumberOfEmployees = 0;			
				accounts.add(a);
			}
			if(xCommit)	insert accounts;
		}
		
		if(xCommit && accounts.size() > 0 && accounts[0].Id == null) insert accounts;								
		
		return accounts;
	}
			
	public List<Contact> getContacts(Boolean xCommit) {
		if(contacts == null) {
			contacts = new List<Contact>();
			for(Integer i = 0; i < contactNum; i++) {
				Contact c = new Contact();
				c.FirstName = 'First ' + i;
				c.LastName = 'Last ' + i;
				c.Email = 'Test@TestNowhere.com';
				//c.Cost__c = 5;
				//c.Hours_Spent__c = 5;
				
				Integer j = Math.mod(i,getAccounts(true).size());
				c.AccountId = getAccounts(true)[j].Id;
				
				contacts.add(c);
			}
			if(xCommit)	insert contacts;
		}
		
		if(xCommit && contacts.size() > 0 && contacts[0].Id == null) insert contacts;
		
		return contacts;
	}

	public void initAllTestData() {
		getUsers(null);
		getAccounts(true);
		getContacts(true);
	}

 	static testMethod void TestDataGeneratorUnitTest() {
        TestDataGenerator_LookupRollupSummary dataGenerator = new TestDataGenerator_LookupRollupSummary();
        dataGenerator.initAllTestData();        
        System.assertEquals(dataGenerator.accountNum, dataGenerator.getAccounts(true).size(),'Account size not equal to accountNum');
        
        dataGenerator.getProfileToUserMap(null);       
        System.assertNotEquals(0,dataGenerator.getUsers(null).size());
    }

 	static testMethod void TestDataGeneratorUnitTest_FailedProfiles() {
        TestDataGenerator_LookupRollupSummary dataGenerator = new TestDataGenerator_LookupRollupSummary();               
        List<String> badProfiles = new List<String>();
        badProfiles.add('WrongProfile');
        dataGenerator.getProfileToUserMap(badProfiles);       
        System.assertNotEquals(0,dataGenerator.getUsers(null).size());
    }
    
 	static testMethod void TestDataGeneratorUnitTest_FailedCounter() {
        TestDataGenerator_LookupRollupSummary dataGenerator = new TestDataGenerator_LookupRollupSummary();
        dataGenerator.userNum = null;               
        List<String> badProfiles = new List<String>();
        badProfiles.add('WrongProfile');
        dataGenerator.getProfileToUserMap(badProfiles);       
        System.assertNotEquals(0,dataGenerator.getUsers(null).size());
    }    
}