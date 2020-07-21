

public class VFC_Call_Report {
	public String callReportID { get; set; }
	public Call_Report__c cr { get; set; }
	public Account a { get; set; }
	public String crName;
	public String errorMsg { get; set; }


	public Boolean canEmailReport {get;set;}

	// class members related to Unit

	public List<UnitWrapper> unitList { get; set; }
	public Set<ID> selectedUnitIDSet;
	public String unitSearchInput { get; set; }
	public List<UnitWrapper> searchedUnitList { get; set; }
	public String unitToChangeSelection { get; set; }
	public String opptyToChangeSelection { get; set; }
	public Boolean newSelectionState { get; set; }
	public class UnitWrapper {
		public Call_Report_Unit__c crUnit { get; set; }
		public Jeopardy_Assessment__c crUnitJeopardy { get; set; }
		public Boolean selected { get; set; }

		// this is to display opportunities for each unit
		public List<OpptyWrapper> openOpptyList { get; set; }
	}
	public class OpptyWrapper {
		public Call_Report_Opportunity__c crOppty { get; set; }
		public Boolean selected { get; set; }
	}

	// class members to help select jeopardy question values
	public String jeopardyQuestion { get; set; }
	public String questionValue { get; set; }

	// class members to help display Opportunities under Units

	public Map<String, UnitWrapper> selectedUnitWrappedMap { get; set; }
	public List<UnitWrapper> getSelectedUnitWrappedList() {
		if( selectedUnitWrappedMap == null ) {
			system.debug( 'selectedUnitWrappedMap is null' );
			return new List<UnitWrapper>();
		}
		return selectedUnitWrappedMap.values();
	}

	// class members to help display Contacts

	public Contact newContact { get; set; }
	public String contactSearchInput { get; set; }
	public List<ContactWrapper> searchedContactList { get; set; }
	public List<ContactWrapper> contactList { get; set; }
	public Set<ID> selectedContactIDSet;
	public class ContactWrapper {
		public Call_Report_Attendee__c crContact { get; set; }
		public Boolean selected { get; set; }
	}

	// class members to display product stewardship
	
	public Boolean productStewardshipSelected { get; set; }
	// productStewardshipString is the same as cr.Product__c
	public String productStewardshipString { get; set; }
	// productStewardship is the boolean equivalent of productStewardshipString
	public Boolean productStewardship {
		get {
			productStewardship = convertYesNoToBoolean( productStewardshipString );
			return productStewardship;
		}
		set {
			productStewardship = value;
			productStewardshipString = convertBooleanToYesNo( productStewardship );
		}
	}

	public void switchProductStewardship() {
		System.debug( 'productStewardshipSelected= ' + productStewardshipSelected );
		System.debug( 'cr.Product__c= ' + cr.Product__c );
		productStewardshipString = ( productStewardshipSelected != null && productStewardshipSelected == true ? 'Yes' : 'No' );
	}

	//public Boolean freshARTProductsOnSite { get; set; }
	public String freshARTProductsOnSiteString { get; set; }
	public Boolean freshARTProductsOnSite {
		get {
			freshARTProductsOnSite = convertYesNoToBoolean( freshARTProductsOnSiteString );
			return freshARTProductsOnSite;
		}
		set {
			freshARTProductsOnSite = value;
			freshARTProductsOnSiteString = convertBooleanToYesNo( freshARTProductsOnSite );
		}
	}

	public Boolean convertYesNoToBoolean( String aValue ) {
		if( aValue == null ) {
			return null;
		}
		return aValue == 'Yes';
	}

	public String convertBooleanToYesNo( Boolean aValue ) {
		if( aValue == null ) {
			return null;
		}
		return aValue ? 'Yes' : 'No';
	}

	public List<Call_Report_Product__c> prodList { get; set; }
	public String productSearchInput { get; set; }
	public List<ProductWrapper> searchedProductList { get; set; }
	public String prodToDelete { get; set; }
	public class ProductWrapper {
		public Call_Report_Product__c crProduct { get; set; }
		public Boolean selected { get; set; }
	}

	public Blob fileContent { get; set; }
	public String fileName { get; set; }

	public String targetPlanSearchInput { get; set; }
	public List<TargetPlanWrapper> searchedTargetPlanList { get; set; }
	public class TargetPlanWrapper {
		public Target_Plan__c t { get; set; }
		public Boolean selected { get; set; }
	}
	public String targetPlanName { get; set; }

	// methods

	public VFC_Call_Report() {
		// this is for the desktop-version that has no standard controller
		callReportID = ApexPages.currentPage().getParameters().get( 'callReportID' );
		String theID = ApexPages.currentPage().getParameters().get( 'ID' );

		if( ( callReportID == null || callReportID == '' ) && ( theID == null || theID == '' ) ) {
			// new from Call Report tab?
			errorMsg = 'Not yet implemented.';
			callReportID = null;
			// a = ????
			return;
		}

		// in case call report was passed as "ID" instead of as "callReportID", 
		// fetch the call report to get the account ID
		if( ! theID.startsWith( '001' ) ) {
			callReportID = theID;
			queryCallReport();
			theID = cr.Account__c;

			ApexPages.currentPage().getParameters().put( 'callReportID', callReportID );
			ApexPages.currentPage().getParameters().put( 'ID', theID );
		}

		queryAccount( theID );

		initialize();
	}

	public VFC_Call_Report( ApexPages.StandardController controller ) {
		if( ! Test.isRunningTest() ) {
			controller.addFields( new List<String> { 'Name' } );
		}

		callReportID = ApexPages.currentPage().getParameters().get( 'callReportID' );

		String theID = ApexPages.currentPage().getParameters().get( 'ID' );
		if( theID == null ) {
			// new from Call Report tab?
			errorMsg = 'Not yet implemented.';
			callReportID = null;
			// a = ????
			return;
		}

		SObject s = controller.getRecord();
		SObjectType sObjType = s.getSObjectType();
		if( sObjType == Account.sObjectType ) {
			a = (Account) s;
		} else {
			cr = (Call_Report__c) s;
			callReportID = cr.ID;

			if( callReportID != null ) {
				queryCallReport();
			}

			queryAccount( cr.Account__c );
		}

		try {
			initialize();
		} catch( Exception e ) {
			System.debug( e );
			errorMsg = 'Error:' + e.getMessage() + ' - ' + e.getStackTraceString();
			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR
						, errorMsg ) );
		}


	}

	public void initialize() {
		System.debug( 'initialize()' );

		fileName = '';
		fileContent = Blob.valueOf( '' );

		currentPage = 'Customer Strategy';	//'Units';

		newContact = new Contact();
		crName = a.Name + ' - ' + Date.today().format();
		System.debug( 'crName= ' + crName );

		if( cr == null ) {
			cr = new Call_Report__c();
			cr.Account__c = a.ID;
			cr.OwnerID = UserInfo.getUserId();
			//cr.Name = getNewName( crName, null );
			cr.Name = getNewName( crName, cr.Call_Report_Name_Append__c );
			cr.Product__c = 'No';
		}

		// NOTE:  productStewardship (boolean) is used in mobile while productStewardshipString is used in desktop
		// in mobile we use flipswitch that only handles Yes/No (true/false) and not nulls
		// it was getting too complicated with many side effects when keeping a single variable for both
		productStewardshipString = cr.Product__c;
		productStewardship = convertYesNoToBoolean( productStewardshipString );
		freshARTProductsOnSiteString = cr.Fresh_TRACompany_Products_On_Site__c;
		freshARTProductsOnSite = convertYesNoToBoolean( freshARTProductsOnSiteString );
		System.debug( 'productStewardshipString= ' + productStewardshipString );
		System.debug( 'freshARTProductsOnSiteString= ' + freshARTProductsOnSiteString );
		
		// initialize units
		unitList = new List<UnitWrapper>();
		selectedUnitIDSet = new Set<ID>();
		selectedUnitWrappedMap = new Map<String, UnitWrapper>();
		
		// initialize contacts
		contactList = new List<ContactWrapper>();
		selectedContactIDSet = new Set<ID>();

		// get the contact for the user
		Boolean userContactSelected = false;
		Contact userContact;
		List<Contact> userContactList = 
					[ SELECT ID, FirstName, LastName, Title, Status__c 
						FROM Contact 
						WHERE SFDC_User_Record__c = :UserInfo.getUserId()
							AND RecordType.Name = 'Internal Employee' 
						LIMIT 1 ];
		if( userContactList.size() > 0 ) {
			userContact = userContactList[ 0 ];
		}

		// get selected units if editing
		if( callReportID != null ) {
			queryCallReport();

			List<Call_Report_Unit__c> cruList = 
				[ SELECT ID, Call_Report__c, Unit__c, Unit__r.Name, Unit__r.AIMS_Unit_ID__c
				FROM Call_Report_Unit__c 
				WHERE Call_Report__c = :callReportID ];

			Set<ID> unitSet = new Set<ID> ();
			for( Call_Report_Unit__c cru : cruList ) {
				cru.Name = getNewName( crName, cru.Unit__r.Name );
				UnitWrapper uw = new UnitWrapper();
				uw.crUnit = cru;
				uw.crUnitJeopardy = new Jeopardy_Assessment__c();
				uw.crUnitJeopardy.Unit__c = cru.Unit__c;
				uw.selected = true;
				unitList.add( uw );

				registerUnitSelection( uw, true );

				unitSet.add( cru.Unit__c );
			}

			// get jeopardy questions and assign them to the respective call report unit
			List<Jeopardy_Assessment__c> jeopardyList =
					[ SELECT ID, Name, Account__c, Change_at_the_Customer__c, Change_in_Acct_Management__c
							, Change_in_the_Business_Climate__c, Competition__c, Complacency__c
							, Does_the_customer_issue_ITB_RFQ__c, Do_we_have_a_supply_agreement__c
							, Results_Issues__c, Change_at_Customer_Rating__c, Change_in_Acct_Mgmt_Rating__c
							, Change_in_Business_Climate_Rating__c, Competition_Rating__c, Complacency_Rating__c
							, Results_Issues_Rating__c, Unit__c, Unit__r.Name
					FROM Jeopardy_Assessment__c
					WHERE Unit__c IN :unitSet ];

			// , Supply_Agreement_Rating__c, Customer_Issue_ITB_RFQ_Rating__c

			for( Jeopardy_Assessment__c ja : jeopardyList ) {
				UnitWrapper uw = selectedUnitWrappedMap.get( ja.Unit__r.Name );
				uw.crUnitJeopardy = ja;
			}

			// get selected contacts if editing
			List<Call_Report_Attendee__c> craList = 
				[ SELECT ID, Call_Report__c, Contact__c, Contact__r.FirstName, Contact__r.LastName
					, Contact__r.Title, Contact__r.Status__c
				FROM Call_Report_Attendee__c 
				WHERE Call_Report__c = :callReportID
				ORDER BY Contact__r.LastName, Contact__r.FirstName ];

			for( Call_Report_Attendee__c cra : craList ) {
				// turn of flag indicating that the user contact is already selected
				if( userContact != null && cra.Contact__c == userContact.ID ) {
					userContactSelected = true;
				}

				cra.Name = getNewName( crName, cra.Contact__r.FirstName + ' ' + cra.Contact__r.LastName );
				ContactWrapper cw = new ContactWrapper();
				cw.crContact = cra;
				cw.selected = true;
				contactList.add( cw );

				selectedContactIDSet.add( cra.Contact__c );
			}

			if( cr.Product__c != null ) {
				productStewardshipString = cr.Product__c;
				productStewardship = cr.Product__c == 'Yes'; //( prodList.size() > 0 );
				if( cr.Fresh_TRACompany_Products_On_Site__c != null ) {
					freshARTProductsOnSite = cr.Fresh_TRACompany_Products_On_Site__c == 'Yes';
				}
			}
		}

		// get accounts for refineries related to a customer account
		Map<Id, Account> refineryMap = new Map<Id, Account> ( [ SELECT ID 
										FROM Account 
										WHERE RecordType.Name = 'Refinery' 
											AND ParentID= :a.ID ] );
		Set<ID> refineryIDSet = new Set<ID>();
		refineryIDSet.addAll( refineryMap.keySet() );

		// add the main account (in case instead of it being a customer, it is a refinery)
		refineryIDSet.add( a.ID );

		// get units for this account regardless of being selected
		List<Unit__c> accountUnitList = 
			[ SELECT ID, Name, AIMS_Unit_ID__c
				, ( SELECT ID, Name, Account__c, Change_at_the_Customer__c, Change_in_Acct_Management__c
						, Change_in_the_Business_Climate__c, Competition__c, Complacency__c
						, Does_the_customer_issue_ITB_RFQ__c, Do_we_have_a_supply_agreement__c
						, Results_Issues__c, Change_at_Customer_Rating__c, Change_in_Acct_Mgmt_Rating__c
						, Change_in_Business_Climate_Rating__c, Competition_Rating__c, Complacency_Rating__c
						, Results_Issues_Rating__c, Unit__c, Unit__r.Name
					FROM Jeopardy_Assessment__r
					ORDER BY CreatedDate DESC
					LIMIT 1 )
				FROM Unit__c 
				WHERE Refinery__c IN :refineryIDSet ];

		// , Supply_Agreement_Rating__c, Customer_Issue_ITB_RFQ_Rating__c

		for( Unit__c u : accountUnitList ) {
			// skip units already in the list
			if( selectedUnitIDSet.contains( u.ID ) ) {
				continue;
			}

			UnitWrapper uw = new UnitWrapper();
			Call_Report_Unit__c cru = new Call_Report_Unit__c();
			cru.Name = getNewName( crName, u.Name );
			cru.Unit__c = u.ID;
			cru.Unit__r = u;
			uw.crUnit = cru;
			uw.selected = false;
			if( u.Jeopardy_Assessment__r != null && u.Jeopardy_Assessment__r.size() > 0 ) {
				uw.crUnitJeopardy = u.Jeopardy_Assessment__r[0];

			} else {
				uw.crUnitJeopardy = new Jeopardy_Assessment__c();
				uw.crUnitJeopardy.Unit__c = u.ID;
			}
			//uw.crUnitJeopardy.Unit__c = u.ID;
			unitList.add( uw );
		}

		// retrieve list of opportunities
		refreshOpptyList();

		// get contacts for this account regardless of being selected
		List<Contact> accountContactList = 
			[ SELECT ID, FirstName, LastName, Title, Status__c
				FROM Contact 
				WHERE AccountID = :a.ID
				ORDER BY LastName, FirstName ];

		for( Contact c : accountContactList ) {
			// skip units already in the list
			if( selectedContactIDSet.contains( c.ID ) ) {
				continue;
			}

			ContactWrapper cw = new ContactWrapper();
			Call_Report_Attendee__c cra = new Call_Report_Attendee__c();
			cra.Name = getNewName( crName, c.FirstName + ' ' + c.LastName );
			cra.Contact__c = c.ID;
			cra.Contact__r = c;
			cw.crContact = cra;
			cw.selected = false;
			contactList.add( cw );
		}

		// add the contact for the current user
		if( ! userContactSelected && userContact != null ) {
			ContactWrapper cw = new ContactWrapper();
			Call_Report_Attendee__c cra = new Call_Report_Attendee__c();
			cra.Name = getNewName( crName, userContact.FirstName + ' ' + userContact.LastName );
			cra.Contact__c = userContact.ID;
			cra.Contact__r = userContact;
			cw.crContact = cra;
			cw.selected = true;
			addContactToList( cw );

		}


		// retrieve product stewardship list
		prodList = [ SELECT ID, Name, Call_Report__c, Product__c, Product__r.Name, SDS_Provided__c, SDS_Number__c
					FROM Call_Report_Product__c 
					WHERE Call_Report__c = :callReportID ];

		for( Call_Report_Product__c crp : prodList ) {
			crp.Name = getNewName( crName, crp.Product__r.Name );
		}

		// 11/16/2017 rwd -- Sending the Call Report
		canEmailReport = false;
		if ( String.isNotBlank( callReportID ) )
		{
			canEmailReport = true;
		}
	}

	// 11/16/2017 rwd -- Sending the Call Report
	public PageReference sendCallReport()
	{
		// CCWS 12/1/2017 Save before send
		saveCallReport();
		
		return CallReportHelper.getEmailTemplatePageRef( callReportID );
	}

	public void addContactToList( ContactWrapper cw ) {
		// add contact to the top of the list
		if( contactList.size() > 0 ) {
			contactList.add( 0, cw );
		} else {
			contactList.add( cw );
		}
	}

	public String getNewName( String prefix, String suffix ) {
		String newName = prefix + ( suffix != null ? ' - ' + suffix : '' );
		return newName.left( 80 );
	}

	public void queryCallReport() {
		List<Call_Report__c> crList = 
			[ SELECT ID, Account__c, Name, Executive_Summary__c, Pre_Call_Plan__c, Details__c
					, Has_an_Account_Strategy_been_written__c, Has_a_Value_Proposition_been_established__c
					, Do_we_have_ALL_the_right_relationships__c, Does_TRACompany_have_an_advantage_commercially__c
					, Type__c, Date_Completed__c, Product__c, Fresh_TRACompany_Products_On_Site__c
					, Call_Report_Name_Append__c, Account_Strategy_Detail__c, Value_Proposition_Detail__c
					, Account_Relationship_Detail__c, Commercial_Advantage_Detail__c 
					, OwnerID, Status__c, Target_Plan__c
					, Competitive_intel__c
				FROM Call_Report__c 
				WHERE ID = :callReportID ];
		System.debug( crList );
		if( crList.size() > 0 ) {
			cr = crList[ 0 ];
			crName = cr.Name;
		}
	}

	public void queryAccount( String acctID ) {
		// query account
		a = [ SELECT ID, Name 
			FROM Account 
			WHERE ID = :acctID ];
	}

	public List<String> getTypePicklist() {
		Schema.SObjectField f = Call_Report__c.Type__c;
		Schema.DescribeFieldResult fr = f.getDescribe();
		List<Schema.PicklistEntry> pleList = fr.getPicklistValues();

		List<String> typeValueList = new List<String>();
		for( Schema.PicklistEntry p : pleList ) {
			typeValueList.add( p.getLabel() );
		}

		return typeValueList;
	}


	public static Map<String, String> jeopardyDependencyMap = new Map<String, String>{
			'Change_at_Customer_Rating__c' => 'Change_at_the_Customer__c'
			, 'Change_in_Acct_Mgmt_Rating__c' => 'Change_in_Acct_Management__c'
			, 'Change_in_Business_Climate_Rating__c' => 'Change_in_the_Business_Climate__c'
			, 'Competition_Rating__c' => 'Competition__c'
			, 'Complacency_Rating__c' => 'Complacency__c'
			, 'Customer_Issue_ITB_RFQ_Rating__c' => 'Does_the_customer_issue_ITB_RFQ__c'
			, 'Supply_Agreement_Rating__c' => 'Do_we_have_a_supply_agreement__c'
			, 'Results_Issues_Rating__c' => 'Results_Issues__c'
	};

	public void jeopardyClick() {
		System.debug( 'unitToChangeSelection= ' + unitToChangeSelection );
		System.debug( 'jeopardyQuestion= ' + jeopardyQuestion );
		System.debug( 'questionValue= ' + questionValue );

		UnitWrapper theUnit = selectedUnitWrappedMap.get( unitToChangeSelection );
		if( theUnit == null ) {
			System.debug( 'unit not found in map' );
			return;
		}

		Jeopardy_Assessment__c ja = theUnit.crUnitJeopardy;

		// assign value based on dependency between fields
		String controllingField = jeopardyDependencyMap.get( jeopardyQuestion );
		system.debug( 'Jeopardy controlling field= ' + controllingField );

		// if controlling field is Yes, assign the number the user clicked, otherwise, nullify it
		String valueToSet = questionValue;
		if( ja.get( controllingField ) == 'No' ) {
			valueToSet = null;
		}
		ja.put( jeopardyQuestion, valueToSet );

		system.debug( 'Jeopardy Question= ' + ja );
	}

	public void unitSelectionChanged() {
		// NOTE: in the mobile page, checking the checkboxes is not applying the selection in the controller
		// so the mobile page has to call this method

		// this bug fix forces the checkboxes to respond when checked/unchecked
		System.debug( 'unitToChangeSelection= ' + unitToChangeSelection );
		System.debug( 'newSelectionState= ' + newSelectionState );

		UnitWrapper theUnit = selectedUnitWrappedMap.get( unitToChangeSelection );
		if( theUnit == null ) {
			System.debug( 'unit not found in map' );
			// find and add the newly selected unit
			for( UnitWrapper uw : unitList ) {
				if( uw.crUnit.Unit__r.Name != unitToChangeSelection ) {
					continue;
				}
				theUnit = uw;
				break;
			}
		}
		
		System.debug( 'old selection state= ' + theUnit.selected );
		registerUnitSelection( theUnit, newSelectionState );
	}
	/*
	public void opptySelectionChanged() {
		// NOTE: in the mobile page, checking the checkboxes is not applying the selection in the controller
		// so the mobile page has to call this method

		// this bug fix forces the checkboxes to respond when checked/unchecked
		System.debug( 'unitToChangeSelection= ' + unitToChangeSelection );
		System.debug( 'opptyToChangeSelection= ' + opptyToChangeSelection );
		System.debug( 'newSelectionState= ' + newSelectionState );

		UnitWrapper theUnit = selectedUnitWrappedMap.get( unitToChangeSelection );
		if( theUnit == null ) {
			System.debug( 'unit not found in map' );
			// find and add the newly selected unit
			for( UnitWrapper uw : getSelectedUnitWrappedList() ) {
				if( uw.crUnit.Unit__r.Name != unitToChangeSelection ) {
					continue;
				}
				theUnit = uw;
				break;
			}
		}
		
		System.debug( theUnit );
		System.debug( theUnit.openOpptyList );

		OpptyWrapper theOppty;
		for( OpptyWrapper ow : theUnit.openOpptyList ) {
			if( ow.crOppty.Opportunity__r.Name == opptyToChangeSelection ) {
				theOppty = ow;
				break;
			}
		}
		
		System.debug( 'old selection state= ' + theOppty.selected );
		theOppty.selected = newSelectionState;
	}
	*/

	public void refreshOpptyList() {
		System.debug( 'refreshOpptyList()' );

		System.debug( 'callReportID= ' + callReportID );

		// NOTE:  by now all selected units should be in the respective collections
		// so no need to review unitList
		//
		//// determine what units were selected
		//syncUnitSelections();

		// determine what opportunities are already in the list
		Set<ID> opptyIDSet = new Set<ID>();
		for( UnitWrapper uw : unitList ) {
			if( uw.openOpptyList == null ) {
				continue;
			}

			for( OpptyWrapper ow : uw.openOpptyList ) {
				opptyIDSet.add( ow.crOppty.Opportunity__c );
			}
		}

		// get selected oppties if editing
		if( callReportID != null ) {
			List<Call_Report_Opportunity__c> croList = 
				[ SELECT ID, Call_Report__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.CloseDate
					, Opportunity__r.Unit__c, Opportunity__r.Unit__r.Name, Opportunity__r.Turn_Around_Date__c 
				FROM Call_Report_Opportunity__c 
				WHERE Call_Report__c = :callReportID ];

			for( Call_Report_Opportunity__c cro : croList ) {
				System.debug( 'Oppty from CRO= ' + cro.Opportunity__c );
				// skip oppty already selected
				if( opptyIDSet.contains( cro.Opportunity__c ) ) {
					continue;
				}

				// locate the unit wrapper
				UnitWrapper uw = selectedUnitWrappedMap.get( cro.Opportunity__r.Unit__r.Name );
				if( uw == null ) {
					// unit was selected initially, but now it is no longer selected
					continue;
				}
				
				cro.Name = getNewName( crName, cro.Opportunity__r.Name );

				OpptyWrapper ow = new OpptyWrapper();
				ow.crOppty = cro;
				ow.selected = true;

				// add oppty to the oppty list inside the unit wrapper
				if( uw.openOpptyList == null ) {
					uw.openOpptyList = new List<OpptyWrapper>();
				}
				uw.openOpptyList.add( ow );
				System.debug( 'added= ' + ow );

				opptyIDSet.add( cro.Opportunity__c );
			}
		}
		System.debug( 'opptyIDSet= ' + opptyIDSet );
		System.debug( selectedUnitWrappedMap.values() );
		
		// get oppties for these units regardless of the oppties being selected
		System.debug( 'selectedUnitIDSet= ' + selectedUnitIDSet );
		List<Opportunity> openOpptyList = [ SELECT ID, Name, CloseDate, Unit__c, Unit__r.Name, Turn_Around_Date__c
											FROM Opportunity 
											WHERE Unit__c IN :selectedUnitIDSet 
												AND IsClosed = false ];

		for( Opportunity o : openOpptyList ) {
			System.debug( 'Oppty from unit= ' + o );
			// skip oppty already selected
			if( opptyIDSet.contains( o.ID ) ) {
				continue;
			}
			
			// locate the unit wrapper
			UnitWrapper uw = selectedUnitWrappedMap.get( o.Unit__r.Name );
			if( uw == null ) {
				continue;
			}

			Call_Report_Opportunity__c cro = new Call_Report_Opportunity__c();
			cro.Name = getNewName( crName, o.Name );
			if( callReportID != null && callReportID != '' ) {
				cro.Call_Report__c = callReportID;
			}
			cro.Opportunity__c = o.ID;
			cro.Opportunity__r = o;

			OpptyWrapper ow = new OpptyWrapper();
			ow.crOppty = cro;
			ow.selected = false;

			// add oppty to the oppty list inside the unit wrapper
			if( uw.openOpptyList == null ) {
				uw.openOpptyList = new List<OpptyWrapper>();
			}
			uw.openOpptyList.add( ow );
			system.debug( 'added= ' + ow );

			opptyIDSet.add( ow.crOppty.Opportunity__c );
		}

		System.debug( 'end refreshOpptyList()' );
		//System.debug( selectedUnitWrappedMap.values() );
	}

	public void syncUnitSelections() {
		System.debug( unitList );
		// determine what units were selected
		for( UnitWrapper uw : unitList ) {
			System.debug( 'uw= ' + uw );
			registerUnitSelection( uw, uw.selected );
		}
	}

	public void registerUnitSelection( UnitWrapper uw, Boolean selected ) {
		if( ! selected ) {
			System.debug( 'desselecting ' + uw.crUnit.Unit__r.Name );
			// if not selected, clear the list of open oppties and remove it from selected map
			uw.selected = false;
			uw.openOpptyList = null;
			selectedUnitWrappedMap.remove( uw.crUnit.Unit__r.Name );
			selectedUnitIDSet.remove( uw.crUnit.Unit__c );
			return;
		}

		System.debug( 'selecting ' + uw.crUnit.Unit__r.Name );
		uw.selected = true;
		uw.openOpptyList = new List<OpptyWrapper>();
		selectedUnitWrappedMap.put( uw.crUnit.Unit__r.Name, uw );
		selectedUnitIDSet.add( uw.crUnit.Unit__c );
	}

	public void searchUnits() {
		System.debug( 'unitSearchInput= ' + unitSearchInput );
		if( unitSearchInput == null ) {
			return;
		}

		// retrieve units that match search criteria
		String unitSearch = '%' + unitSearchInput + '%';
		List<Unit__c> unitSearchList = 
			[ SELECT ID, Name, AIMS_Unit_ID__c
				, ( SELECT ID, Name, Account__c, Change_at_the_Customer__c, Change_in_Acct_Management__c
						, Change_in_the_Business_Climate__c, Competition__c, Complacency__c
						, Does_the_customer_issue_ITB_RFQ__c, Do_we_have_a_supply_agreement__c
						, Results_Issues__c, Change_at_Customer_Rating__c, Change_in_Acct_Mgmt_Rating__c
						, Change_in_Business_Climate_Rating__c, Competition_Rating__c, Complacency_Rating__c
						, Results_Issues_Rating__c, Unit__c, Unit__r.Name
					FROM Jeopardy_Assessment__r
					LIMIT 1 )
				FROM Unit__c 
				WHERE Name LIKE :unitSearch 
					OR AIMS_Unit_ID__c = :unitSearchInput ];
		if( unitSearchList.size() <= 0 ) {
			return;
		}

		// build list of wrapped units for selection
		searchedUnitList = new List<UnitWrapper>();
		for( Unit__c u : unitSearchList ) {
			UnitWrapper uw = new UnitWrapper();
			Call_Report_Unit__c cru = new Call_Report_Unit__c();
			cru.Name = getNewName( crName, u.Name );
			if( callReportID != null && callReportID != '' ) {
				cru.Call_Report__c = callReportID;
			}
			cru.Unit__c = u.ID;
			cru.Unit__r = u;
			uw.crUnit = cru;

			if( u.Jeopardy_Assessment__r != null && u.Jeopardy_Assessment__r.size() > 0 ) {
				uw.crUnitJeopardy = u.Jeopardy_Assessment__r[ 0 ];

			} else {
				uw.crUnitJeopardy = new Jeopardy_Assessment__c();
				uw.crUnitJeopardy.Unit__c = u.ID;
			}

			uw.selected = false;
			searchedUnitList.add( uw );
		}
	}

	public void addSelectedUnits() {
		System.debug( 'addSelectedUnits()' );
		System.debug( 'searchedUnitList= ' + searchedUnitList );

		goBack();

		if( searchedUnitList == null ) {
			return;
		}

		// determine what units were already selected
		syncUnitSelections();

		// copy selected units to the main list
		for( UnitWrapper uw : searchedUnitList ) {
			// skip units already in the list
			if( selectedUnitIDSet.contains( uw.crUnit.Unit__c ) ) {
				continue;
			}

			if( uw.selected ) {
				// TODO: detect whether this unit is already in the list unselected and select it instead of adding
				
				unitList.add( uw );
				registerUnitSelection( uw, true );
				System.debug( 'added unit= ' + uw.crUnit.Unit__r.Name );
			}
		}

		// refresh list of opportunities with the new selected units
		refreshOpptyList();
	}

	public void validateCallReport() {
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType callReportSchema = schemaMap.get( 'Call_Report__c' );
		Map<String, Schema.SObjectField> fieldMap = callReportSchema.getDescribe().fields.getMap();

		errorMsg = '';

		//errorMsg = 'Testing error message';

		List<String> requiredFieldList = new List<String> {
			'Date_Completed__c', 'Type__c'	//, 'Pre_Call_Plan__c', 'Executive_Summary__c', 'Details__c'
		};

		for( String requiredField : requiredFieldList ) {
			if( cr.get( requiredField ) == null || String.valueOf( cr.get( requiredField ) ) == '' ) {
				errorMsg += '<br /><li>' + fieldMap.get( requiredField ).getDescribe().getLabel() + ' is required.</li>';
			}
		}

		// convert flag from boolean to string
		String convertedPSFlag = convertProdStewardFlag();

		//if( productStewardshipString == null && productStewardship == null ) {
		if( convertedPSFlag == null ) {
			errorMsg += '<br /><li>' + fieldMap.get( 'Product__c' ).getDescribe().getLabel() + ' is required.</li>';
		} else {
			if( convertedPSFlag == 'Yes' && freshARTProductsOnSite == null ) {
				errorMsg += '<br /><li>' + fieldMap.get( 'Fresh_TRACompany_Products_On_Site__c' ).getDescribe().getLabel() + ' is required.</li>';
			}
		}

		//if( productStewardship && ( productStewardshipString == 'Yes' ) && freshARTProductsOnSite ) {
		if( convertedPSFlag == 'Yes' && freshARTProductsOnSite == true && prodList.size() <= 0 ) {
			errorMsg += '<br /><li>Products are required when ' 
					+ fieldMap.get( 'Fresh_TRACompany_Products_On_Site__c' ).getDescribe().getLabel() 
					+ ' is Yes.</li>';
		}
		System.debug( 'errorMsg= ' + errorMsg );
	}

	public String convertProdStewardFlag() {
		String convertedFlag = productStewardshipString;

		// detect whether we are in Salesforce1
		String displayedTheme = UserInfo.getUiThemeDisplayed();
		System.debug( 'displayedTheme= ' + displayedTheme );
		if( displayedTheme == 'Theme4t' || displayedTheme == 'Theme4d' ) {
			// if in Salesforce1, convert flag from boolean to string disregarding nulls
			if( convertedFlag == null ) {
				convertedFlag = ( productStewardship == true ? 'Yes' : 'No' );
			}
			return convertedFlag;
		}

		// if on desktop, just use the string version of the flag
		return convertedFlag;

		/*
		String convertedFlag = productStewardshipString;
		// convert flag from boolean to string
		if( convertedFlag == null ) {
			convertedFlag = ( productStewardship == true ? 'Yes' : 'No' );
		}
		//if( productStewardshipString == null && productStewardship != null ) {
			//productStewardshipString = ( productStewardship ? 'Yes' : 'No' );
		//}
		return convertedFlag;
		*/
	}

	/*
	// Has_an_Account_Strategy_been_written__c => Account_Strategy_Detail__c
	// Has_a_Value_Proposition_been_established__c => Value_Proposition_Detail__c
	// Do_we_have_ALL_the_right_relationships__c => Account_Relationship_Detail__c
	// Does_TRACompany_have_an_advantage_commercially__c => Commercial_Advantage_Detail__c
	private void deleteDetailsIfNotNeeded()
	{
		if(cr != null)
		{
			if (cr.Has_an_Account_Strategy_been_written__c == false)
				cr.Account_Strategy_Detail__c = null;

			if (cr.Has_a_Value_Proposition_been_established__c == false)
				cr.Value_Proposition_Detail__c = null;

			if (cr.Do_we_have_ALL_the_right_relationships__c == false)
				cr.Account_Relationship_Detail__c = null;

			if (cr.Does_TRACompany_have_an_advantage_commercially__c == false)
				cr.Commercial_Advantage_Detail__c = null;
		}
	}
   */

	public void saveCallReport() {
		System.debug( 'saveCallReport()' );
		//System.debug( selectedUnitWrappedMap.values() );

		errorMsg = '';

		Boolean isInsert = ( cr.ID == null );

		try {
			// NOTE:  for desktop, productStewardshipString should stay null if the user didn't click it
			// but for mobile, it defaults to No (because of flipswitch and all the side effects)

			//// convert flag from boolean to string
			//convertProdStewardFlag();

			//if( productStewardshipString != null || productStewardship != null ) {
			System.debug( 'productStewardship= ' + productStewardship );
			System.debug( 'productStewardshipString= ' + productStewardshipString );
			if( productStewardshipString != null ) {
				cr.Product__c = productStewardshipString;
				//cr.Product__c = productStewardship ? 'Yes' : 'No';

				if( cr.Product__c == 'Yes' ) {
					System.debug( 'freshARTProductsOnSite= ' + freshARTProductsOnSite );
					cr.Fresh_TRACompany_Products_On_Site__c = freshARTProductsOnSite == true ? 'Yes' : 'No';
				}
			}

			//cr.Name = getNewName( a.Name, ( cr.Date_Completed__c != null ? cr.Date_Completed__c.format() : '' ) );
			cr.Name = getNewName( a.Name, cr.Call_Report_Name_Append__c );

			if( cr.Call_Report_Name_Append__c != null && ! cr.Name.contains( cr.Call_Report_Name_Append__c ) ) {
				cr.Name = cr.Name +  ' ' + cr.Call_Report_Name_Append__c;
			}

			// CCWS Check if picklists are "no" and then delete the "Detail" notes field
			//deleteDetailsIfNotNeeded();

			system.debug( cr );

			// save call report object
			upsert cr;
			callReportID = cr.ID;


			// collect the selected units/oppties in Call_Report_Unit__c
			List<Call_Report_Unit__c> crUnitsToSaveList = new List<Call_Report_Unit__c>();
			List<Call_Report_Opportunity__c> crOpptiesToSaveList = new List<Call_Report_Opportunity__c>();
			List<Jeopardy_Assessment__c> jeopardyQuestionsToSaveList = new List<Jeopardy_Assessment__c>();

			// NOTE:  for some reason we could not rely on the selected state of unitList so we use this map instead
			for( UnitWrapper uw : selectedUnitWrappedMap.values() ) {
				System.debug( uw );
				if( ! uw.selected ) {
					continue;
				}

				// clone without ID since we're deleting the old records and recreating them
				Call_Report_Unit__c cru = uw.crUnit.clone();
				cru.Call_Report__c = callReportID;
				crUnitsToSaveList.add( cru );

				// copy the jeopardy for each unit, if any field has been selected
				if( jeopardyWasEntered( uw.crUnitJeopardy ) == true ) {
					jeopardyQuestionsToSaveList.add(uw.crUnitJeopardy);
				}

				System.debug( 'Oppties for ' + cru.Unit__r.Name + '= ' + uw.openOpptyList );
				if( uw.openOpptyList == null ) {
					continue;
				}

				for( OpptyWrapper ow : uw.openOpptyList ) {
					if( ! ow.selected ) {
						continue;
					}

					// clone without ID since we're deleting the old records and recreating them
					Call_Report_Opportunity__c cro = ow.crOppty.clone();
					cro.Call_Report__c = callReportID;
					crOpptiesToSaveList.add( cro );
				}
			}

			// collect the selected contacts in Call_Report_Unit__c
			List<Call_Report_Attendee__c> crContactsToSaveList = new List<Call_Report_Attendee__c>();
			for( ContactWrapper cw : contactList ) {
				if( ! cw.selected ) {
					continue;
				}
				// clone without the ID since we're deleting the old records and recreating them
				Call_Report_Attendee__c cra = cw.crContact.clone();
				cra.Call_Report__c = callReportID;
				crContactsToSaveList.add( cra );
			}

			// save selected units
			delete [ SELECT ID FROM Call_Report_Unit__c WHERE Call_Report__c = :callReportID ];
			System.debug( crUnitsToSaveList );
			if( crUnitsToSaveList.size() > 0 ) {
				insert crUnitsToSaveList;
			}

			// save jeopardy questions
			system.debug( jeopardyQuestionsToSaveList );
			if( jeopardyQuestionsToSaveList.size() > 0 ) {
				upsert jeopardyQuestionsToSaveList;
			}

			// save selected optties
			delete [ SELECT ID FROM Call_Report_Opportunity__c WHERE Call_Report__c = :callReportID ];
			if( crOpptiesToSaveList.size() > 0 ) {
				insert crOpptiesToSaveList;
			}

			// save selected contacts
			delete [ SELECT ID FROM Call_Report_Attendee__c WHERE Call_Report__c = :callReportID ];
			if( crContactsToSaveList.size() > 0 ) {
				insert crContactsToSaveList;
			}
			
			// delete products if no longer needed
			if( cr.Product__c == 'No' ) { //|| cr.Fresh_TRACompany_Products_On_Site__c == 'No' ) {
				System.debug( 'deleting previous call report produts' );
				delete [ SELECT ID FROM Call_Report_Product__c WHERE Call_Report__c = :callReportID ];

			} else {
				// save product stewardship
				for( Call_Report_Product__c crp : prodList ) {
					if( crp.Call_Report__c == null ) {
						crp.Call_Report__c = callReportID;
					}
				}
				System.debug( prodList );
				upsert prodList;
			}

		} catch( Exception e ) {
			errorMsg = Label.CallReport_SaveError + ' ' + e.getMessage();
			System.debug( errorMsg );
			System.debug( e.getStackTraceString() );

			// in case of insert failed, clear the ID
			if( isInsert ) {
				callReportID = null;
			}

			return;
		}
		System.debug( 'end saveCallReport()' );
	}

	public Boolean jeopardyWasEntered( Jeopardy_Assessment__c crUnitJeopardy ) {
		if( crUnitJeopardy.Results_Issues__c == null
				&& crUnitJeopardy.Change_in_Acct_Management__c == null
				&& crUnitJeopardy.Change_at_the_Customer__c == null
				&& crUnitJeopardy.Change_in_the_Business_Climate__c == null
				&& crUnitJeopardy.Complacency__c == null
				&& crUnitJeopardy.Competition__c == null
				&& crUnitJeopardy.Do_we_have_a_supply_agreement__c == null
				&& crUnitJeopardy.Does_the_customer_issue_ITB_RFQ__c == null ) {
			return false;
		}

		return true;
	}
	
	public void searchContacts() {
		searchedContactList = new List<ContactWrapper>();

		System.debug( 'contactSearchInput= ' + contactSearchInput );
		if( contactSearchInput == null ) {
			return;
		}

		// retrieve units that match search criteria
		contactSearchInput = String.escapeSingleQuotes( contactSearchInput );
		String maskedInput = '%' + contactSearchInput + '%';
		String[] contactName = contactSearchInput.split( ' ' );
		String firstName = contactName[ 0 ];
		String lastName = firstName;
		if( contactName.size() > 1 ) {
			lastName = contactName[ contactName.size() - 1 ];
		}
		List<Contact> contactSearchList = 
			[ SELECT ID, FirstName, LastName, AccountID, Account.Name
					, Title, Status__c
				FROM Contact 
				WHERE FirstName = :firstName
					OR LastName = :lastName
					OR Account.Name LIKE :maskedInput
				ORDER BY LastName, FirstName
				LIMIT 100 ];
		if( contactSearchList.size() <= 0 ) {
			return;
		}

		// build list of wrapped contacts for selection
		searchedContactList = new List<ContactWrapper>();
		for( Contact c : contactSearchList ) {
			ContactWrapper cw = new ContactWrapper();
			Call_Report_Attendee__c cra = new Call_Report_Attendee__c();
			cra.Name = getNewName( crName, c.FirstName + ' ' + c.LastName );
			cra.Contact__c = c.ID;
			cra.Contact__r = c;
			cw.crContact = cra;
			cw.selected = false;
			searchedContactList.add( cw );
		}
	}

	public void addSelectedContacts() {
		System.debug( 'searchedContactList= ' + searchedContactList );

		// copy selected units to the main list
		for( ContactWrapper cw : searchedContactList ) {
			// skip units already in the list
			if( selectedContactIDSet.contains( cw.crContact.Contact__c ) ) {
				continue;
			}

			if( cw.selected ) {
				// add contact at the top of the list
				addContactToList( cw );
				selectedContactIDSet.add( cw.crContact.Contact__c );
			}
		}

		goBack();
	}

	public void createContact() {
		System.debug( 'newContact= ' + newContact );
		errorMsg = '';

		// save contact and store the error message if any
		try {
			newContact.ID = null;
			newContact.AccountID = a.ID;
			newContact.Status__c = 'Active';
			insert newContact;
		} catch( Exception e ) {
			errorMsg = Label.CallReport_NewContactError + '<br />' + e.getMessage();
			System.debug( errorMsg );
			System.debug( e.getStackTraceString() );
			return;
		}
		
		// add new contact to the list at the top of the list
		ContactWrapper cw = new ContactWrapper();
		Call_Report_Attendee__c cra = new Call_Report_Attendee__c();
		cra.Name = getNewName( crName, newContact.FirstName + ' ' + newContact.LastName );
		cra.Contact__c = newContact.ID;
		cra.Contact__r = newContact;
		cw.crContact = cra;
		cw.selected = true;
		addContactToList( cw );
		selectedContactIDSet.add( newContact.ID );

		// reset contact for the next time user adds a new contact
		newContact = new Contact();
	}
	
	public void searchProducts() {
		searchedProductList = new List<ProductWrapper>();

		System.debug( 'productSearchInput= ' + productSearchInput );
		if( productSearchInput == null ) {
			return;
		}

		// retrieve units that match search criteria
		String maskedInput = '%' + String.escapeSingleQuotes( productSearchInput ) + '%';
		List<Product2> productSearchList = 
			[ SELECT ID, Name 
				FROM Product2 
				WHERE Name LIKE :maskedInput
				LIMIT 100 ];
		if( productSearchList.size() <= 0 ) {
			return;
		}

		// build list of wrapped contacts for selection
		for( Product2 p : productSearchList ) {
			ProductWrapper pw = new ProductWrapper();
			Call_Report_Product__c crp = new Call_Report_Product__c();
			crp.Name = getNewName( crName, p.Name );
			crp.Call_Report__c = callReportID;
			crp.Product__c = p.ID;
			crp.Product__r = p;
			pw.crProduct = crp;
			pw.selected = false;
			searchedProductList.add( pw );
		}
	}

	public void addProducts() {
		System.debug( 'searchedProductList= ' + searchedProductList );

		goBack();

		if( searchedProductList == null ) {
			return;
		}

		// create set to prevent selecting the same product again
		Set<String> productNameSet = new Set<String>();
		for( Call_Report_Product__c crp : prodList ) {
			productNameSet.add( crp.Product__r.Name );
		}

		// copy selected units to the main list
		for( ProductWrapper pw : searchedProductList ) {
			// if selected and not already in the list, add to the list
			if( pw.selected && ! productNameSet.contains( pw.crProduct.Product__r.Name ) ) {
				prodList.add( pw.crProduct );
			}
		}
	}

	public void deleteProduct() {
		System.debug( 'prodToDelete= ' + prodToDelete );
		if( prodToDelete == null ) {
			return;
		}

		Call_Report_Product__c crp;
		Integer i = 0;
		for( ; i < prodList.size(); i++ ) {
			Call_Report_Product__c p = prodList[ i ];
			if( prodToDelete == p.Product__r.Name ) {
				crp = p;
				break;
			}
		}

		if( crp != null && crp.ID != null ) {
			try {
				delete crp;
			} catch( Exception e ) {
				errorMsg = Label.CallReport_NewContactError + '<br />' + e.getMessage();
				System.debug( errorMsg );
				System.debug( e.getStackTraceString() );
				return;
			}
		}
		

		prodList.remove( i );
	}

	public void searchTargetPlans() {
		searchedTargetPlanList = new List<TargetPlanWrapper>();

		System.debug( 'targetPlanSearchInput= ' + targetPlanSearchInput );
		if( targetPlanSearchInput == null ) {
			return;
		}

		// retrieve units that match search criteria
		String maskedInput = '%' + String.escapeSingleQuotes( targetPlanSearchInput ) + '%';
		List<Target_Plan__c> targetPlanSearchList =
				[ SELECT ID, Name
					FROM Target_Plan__c
					WHERE Name LIKE :maskedInput
					LIMIT 100 ];
		if( targetPlanSearchList.size() <= 0 ) {
			return;
		}

		targetPlanName = '';

		// build list of wrapped contacts for selection
		for( Target_Plan__c t : targetPlanSearchList ) {
			TargetPlanWrapper tw = new TargetPlanWrapper();
			tw.t = t;
			tw.selected = false;
			searchedTargetPlanList.add( tw );
		}
	}

	public void setTargetPlan() {
		System.debug( 'searchedTargetPlanList= ' + searchedTargetPlanList );

		goBack();

		if( searchedTargetPlanList == null ) {
			return;
		}

		// copy selected units to the main list
		for( TargetPlanWrapper tw : searchedTargetPlanList ) {
			// if selected, set as the call report's target plan
			if( tw.selected ) {
				cr.Target_Plan__c = tw.t.ID;
				targetPlanName = tw.t.Name;
				system.debug( 'cr.Target_Plan__c= ' + cr.Target_Plan__c );
				system.debug( 'targetPlanName= ' + targetPlanName );
				break;
			}
		}
	}
	
	// class members related to non-mobile version

	public String emailPreviewURL { get; set; }

	public PageReference previewEmail() {
		try {
			// validate before redirect to account
			PageReference pr = finalValidation();

			// return in case of errors
			if( pr == null ) {
				return null;
			}

			saveCallReport();

			currentPage = 'Email Preview';

			// get preview URL from custom setting
			Call_Report_Configuration__c crc = Call_Report_Configuration__c.getInstance();
			if( crc == null ) {
				errorMsg = 'The Call Report Configuration setting is missing.';
				ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR
							, errorMsg ) );
				return null;
			}
			System.debug( crc );

			// insert data into placeholders
			emailPreviewURL = crc.Email_Preview_URL__c;
			emailPreviewURL = emailPreviewURL.replace( '{templateID}', crc.Template_ID__c );
			emailPreviewURL = emailPreviewURL.replace( '{baseURL}', crc.Base_URL__c );
			emailPreviewURL = emailPreviewURL.replace( '{callReportID}', callReportID );

			// check whether an email has already been sent for this call report
			// NOTE: changed to not prevent the user from sending the email again
			if( hasAnEmailBeenSent() ) {
				return null;
			}

		} catch( Exception e ) {
			System.debug( e );
			errorMsg = 'Error:' + e.getMessage() + ' - ' + e.getStackTraceString();
			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR
						, errorMsg ) );
			return null;
		}


		return null;
	}

	public Boolean hasAnEmailBeenSent() {

		// check whether an email has already been sent for this call report
		List<Task> taskList = [ SELECT ID, ActivityDate, WhatID 
								FROM Task 
								WHERE TaskSubType = 'Email'
									AND Status = 'Completed'
									AND Subject LIKE 'Email:%'
									AND WhatID = :callReportID 
								ORDER BY ActivityDate DESC 
								LIMIT 1 ];
		if( taskList.size() > 0 ) {
			System.debug( 'Email had already been sent.' );
			errorMsg = 'An email has already been sent for this call report on '
						+ taskList[ 0 ].ActivityDate.format() + '.';
			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR
						, errorMsg ) );
			return true;
		}

		System.debug( 'Email has not yet been sent.' );
		return false;
	}

	public PageReference mobileSendEmail() {
		return sendEmail( true );
	}

	public PageReference sendEmail() {
		return sendEmail( false );
	}

	public PageReference sendEmail( Boolean checkPreviousEmail ) {
		try {

			// check whether an email has already been sent for this call report
			// if on mobile prevent the user from sending the email again
			if( checkPreviousEmail && hasAnEmailBeenSent() ) {
				return null;
			}

			// get contact ID from custom setting
			Call_Report_Configuration__c crc = Call_Report_Configuration__c.getInstance();
			if( crc == null ) {
				errorMsg = 'The Call Report Configuration setting is missing.';
				ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR
							, errorMsg ) );
				return null;
			}

			String toList = crc.Email_address_To_List__c;
			String[] toArray;
			if( toList != null ) {
				toArray = toList.split( ',' );
			}

			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setTargetObjectId( crc.Contact_ID_to_send_email__c );
			mail.setTemplateId( crc.Template_ID__c );
			mail.setWhatId( callReportID );
			if( toList != null ) {
				mail.setToAddresses( toArray );
			}
			mail.setBccSender( false );
			mail.setUseSignature( false );
			mail.setReplyTo( crc.Sender_Address__c );
			mail.setSenderDisplayName( crc.Sender_Name__c );
			mail.setSaveAsActivity( true ); 
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );

		} catch( Exception e ) {
			System.debug( e );
			errorMsg = 'Error:' + e.getMessage() + ' - ' + e.getStackTraceString();
			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR
						, errorMsg ) );
			return null;
		}

		ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM
					, 'Email has been sent.' ) );
		errorMsg = 'Email Sent';

		return null;
	}

	public String currentPage { get; set; }

	public PageReference navigateToUpload() {

		// save call report to get a call report id to be able to attach file to it
		if( callReportID == null || callReportID == '' ) {
			saveCallReport();
		}
		if( errorMsg != '' ) {
			return null;
		}

		PageReference pr = Page.mobileCallReportUpload;
		system.debug( callReportID );
		pr.getParameters().put( 'callReportID', callReportID );
		pr.getParameters().put( 'ID', a.ID );
		pr.setRedirect( false );
		return pr;
	}

	public PageReference uploadImage() {

		if( fileName == null || fileName == '' 
           		|| fileContent == null || fileContent == Blob.valueOf( '' ) ) {
			errorMsg = 'Please select an image to upload.';

			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR
						, errorMsg ) );

			return null;
		}

		Savepoint sp = Database.setSavepoint();

		// save call report to get a call report id to be able to attach file to it
		if( callReportID == null || callReportID == '' ) {
			saveCallReport();
		}

		system.debug( callReportID );

		try {

			ContentVersion cont = new ContentVersion();
			cont.Title = fileName;
			cont.Description = 'Image for Call Report ' + callReportID;
			cont.PathOnClient = fileName;
			cont.VersionData = fileContent;
			cont.ContentLocation = 'S';	// internal file
			cont.Origin = 'H';
			cont.FirstPublishLocationId = callReportID;
			cont.OwnerId =UserInfo.getUserId();
			cont.SharingPrivacy = 'N';	// anyone

			system.debug( cont );
			insert cont;

			// create ContentDistribution record to share file publicly and get public URL
			ContentDistribution distr = new ContentDistribution();
			distr.Name = fileName;
			distr.ContentVersionId = cont.ID;
			distr.PreferencesAllowViewInBrowser = true;
			distr.PreferencesAllowOriginalDownload = true;
			distr.PreferencesAllowPDFDownload = false;
			distr.PreferencesPasswordRequired = false;
			distr.PreferencesLinkLatestVersion = true;
			distr.PreferencesNotifyOnVisit = false;
			distr.PreferencesNotifyRndtnComplete = false;
			insert distr;

			// fetch public URL
			distr = [
					SELECT ID, ContentVersionId, ContentDocumentId, DistributionPublicUrl
					FROM ContentDistribution
					WHERE ID = :distr.ID
			];

			system.debug( 'public URL= ' + distr.DistributionPublicUrl );

			// save public URL in the call report
			cr.Image_File_URL__C = distr.DistributionPublicUrl;
			update cr;

			//Id contDocId = [ SELECT ContentDocumentId
			//				FROM ContentVersion
			//				WHERE Id = :cont.Id ].ContentDocumentId;
//
			//ContentDocumentLink cdl = new ContentDocumentLink();
			//cdl.ContentDocumentId = contDocId;
			//cdl.LinkedEntityId = callReportID;
			//cdl.ShareType = 'C';	// Collaborator permission	'I'; // Inferred permission
			//cdl.Visibility = 'AllUsers';
//
			//system.debug( cdl );
			//insert cdl;

		} catch( Exception e ) {
			Database.rollback( sp );

			// this is to release viewstate data
			fileContent = Blob.valueOf( '' );

			errorMsg = 'Error when uploading image:  ' + e.getMessage();
			System.debug( errorMsg );
			System.debug( e.getStackTraceString() );

			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR
					, errorMsg + ' - ' + e.getStackTraceString() ) );

			return null;
		}

		// this is to release viewstate data sooner
		fileContent = Blob.valueOf( '' );

		//ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM
		//			, 'File uploaded successfully.' ) );

		System.debug( 'end uploadImage()' );

		return cancelImageDialog();
	}

	public PageReference cancelImageDialog() {
        
        // this is to release viewstate data
        fileContent = Blob.valueOf( '' );

		PageReference pr = Page.Account_Mobile_Call_Report;
		system.debug( callReportID );
		pr.getParameters().put( 'callReportID', callReportID );
		pr.getParameters().put( 'ID', a.ID );
		pr.setRedirect( false );
		return pr;
    }

	public PageReference next() {
	System.debug( 'productStewardship= ' + productStewardship );
	System.debug( 'productStewardshipString= ' + productStewardshipString );
		PageReference pr;

		
		if( currentPage == 'Customer Strategy' ) {
			
			if( productStewardship == true || productStewardshipString == 'Yes' ) {
				currentPage = 'Product Stewardship';

			} else {
				currentPage = 'Units';
			}

		} else
		if( currentPage == 'Product Stewardship' ) {
			currentPage = 'Units';

		} else
		if( currentPage == 'Units' ) {
			currentPage = 'Jeopardy Questions';

		} else
		if( currentPage == 'Jeopardy Questions' ) {
			currentPage = 'Opportunities';

		} else
		if( currentPage == 'Opportunities' ) {
			currentPage = 'Contacts';

		} else
		if( currentPage == 'Contacts' ) {

			// validate before redirect to account
			pr = finalValidation();

			// return in case of errors
			if( pr == null ) {
				return null;
			}

		} else
		if( currentPage == 'Email Preview' ) {
			// validate before redirect to account
			pr = finalValidation();

			// return in case of errors
			if( pr == null ) {
				return null;
			}

		}

		saveCallReport();

		// this is to retrieve opportunities for the units selected most recently
		if( currentPage == 'Opportunities' ) {
			refreshOpptyList();
		}

		return pr;
	}

	public PageReference finalValidation() {
		// validate before redirect to account
		validateCallReport();

		if( errorMsg != '' ) {
			return null;
		}

		currentPage = 'Call_Report__c';
		PageReference pr = new PageReference( '/' + cr.ID );

		return pr;
	}

	public PageReference previous() {
		PageReference pr;

		if( currentPage == 'Customer Strategy' ) {
			currentPage = 'Account';
			pr = new PageReference( '/' + a.ID );

		} else
		if( currentPage == 'Product Stewardship' ) {
			currentPage = 'Customer Strategy';

		} else 
		if( currentPage == 'Units' ) {
			if( productStewardship == true || productStewardshipString == 'Yes' ) {
				currentPage = 'Product Stewardship';

			} else {
				currentPage = 'Customer Strategy';
			}

		} else
		if( currentPage == 'Opportunities' ) {
			currentPage = 'Jeopardy Questions';

		} else
		if( currentPage == 'Jeopardy Questions' ) {
			currentPage = 'Units';

		} else
		if( currentPage == 'Contacts' ) {
			currentPage = 'Opportunities';

		} else
		if( currentPage == 'Email Preview' ) {
			currentPage = 'Contacts';
		}

		saveCallReport();

		return pr;
	}

	public void explicitSave() {
		saveCallReport();

		if( errorMsg == '' ) {
			errorMsg = 'Saved';
		}
	}

	public void saveNewContact() {
		errorMsg = '';
        Boolean hasValidationError = false;
        // validate
		if( newContact.Email == null && newContact.Phone == null ) {
			errorMsg += 'Please enter at least email or phone.\n';
			hasValidationError = true;
		}
        
        // validate
        if(String.isBlank(newContact.FirstName))
        {
            errorMsg += 'Please enter a first name.\n';
			hasValidationError = true;
        }

        // validate
        if(String.isBlank(newContact.LastName))
        {
            errorMsg += 'Please enter a last name.\n';
			hasValidationError = true;
        }
        
        if(hasValidationError)
        {
            return;
        }

		createContact();

		if( errorMsg == '' ) {
			goBack();
		}
	}

	public void goToAddUnits() {
		currentPage = 'Add Units';
	}

	public void goToAddContacts() {
		currentPage = 'Add Contacts';
	}

	public void goToNewContact() {
		currentPage = 'New Contact';
	}

	public void goToAddProducts() {
		currentPage = 'Add Products';
	}

	public void goBack() {
		errorMsg = '';
		if( currentPage == 'Add Units' ) {
			currentPage = 'Units';
		} else 
		if( currentPage == 'Add Contacts' ) {
			currentPage = 'Contacts';
		} else 
		if( currentPage == 'Add Products' ) {
			currentPage = 'Product Stewardship';
		} else 
		if( currentPage == 'New Contact' ) {
			currentPage = 'Contacts';
		}
	}
}