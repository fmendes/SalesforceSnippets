trigger Sample_Child_Trigger on Contact (after delete, after insert, after undelete, after update) 
{

	List<Contact> childObjectList;
	List<Contact> oldChildObjectList;
	if( Trigger.isDelete ) {
		childObjectList = Trigger.old;
	} else {
		childObjectList = Trigger.new;
	} 
	
	
	
	//Pass in the name of the child record, in this case 'Contact' and the name of the parent record, in this case 'Account';	
	LookupRollupHelper lh = new LookupRollupHelper( 'Contact', 'Account');
	
	//Convert the Trigger.list to a list of sObjects
	if(Trigger.isUpdate) {
		lh.rollupSummary((List<sObject>)childObjectList, (List<sObject>)Trigger.old);
	} else {
		lh.rollupSummary((List<sObject>)childObjectList, null);
	}

}