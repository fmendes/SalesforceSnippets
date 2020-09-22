
@isTest
private class ApexActivator_Test {

	static testMethod void testDisabledFalseByDefault() {
		System.assertEquals(false,ApexActivator.isDisabled('Bogus'));
	}

	static testMethod void testDisabledTrue() {

		Apex_Activation_Settings__c settings = Apex_Activation_Settings__c.getInstance();

		if(settings == null) settings = new Apex_Activation_Settings__c();

		settings.Disable_All_Registered_Triggers__c = true;

		if(settings.id != null)
		{
			update settings;
		}
		else
		{
			insert settings;
		}

		System.assertEquals(true,ApexActivator.isDisabled('Bogus'));
	}

}