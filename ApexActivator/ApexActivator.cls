/* USAGE

    if(ApexActivator.isDisabled('Disable Quote Triggers')
    {
        System.debug('Trigger disabled by Apex Activation Settings Custom Setting.');
        return;
    }

 */

public without sharing class ApexActivator
{
	//Defaults to false
	public static Boolean isDisabled(String disable_Trigger_FieldName)
	{
		Boolean isDisabled = false;

		if(disable_Trigger_FieldName != null)
		{
			try
			{
				//Ensure we have a valid custom field name
				if(!disable_Trigger_FieldName.endsWith('__c'))
				{
					disable_Trigger_FieldName += '__c';
				}

				//Ensure we have a valid custom field name
				disable_Trigger_FieldName = disable_Trigger_FieldName.replaceAll(' ', '_');

				Apex_Activation_Settings__c settings = Apex_Activation_Settings__c.getInstance();

				if (settings != null && settings.Disable_All_Registered_Triggers__c == true || (Boolean)((SObject)settings).get(disable_Trigger_FieldName) == true)
				{
					isDisabled = true;
				}
			}
			catch(Exception exp)
			{
				System.debug('ApexActivator: is Disabled: IGNORE EXCEPTION: ' + exp);
			}
		}

		return isDisabled;
	}

}