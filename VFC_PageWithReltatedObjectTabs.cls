public with sharing class VFC_PageWithReltatedObjectTabs {

    public List<String> tabList = new List<String> { 'daily', 'location', 'crew'
            , 'equipment', 'subcontractor' };

    public String selectedTab {
        get;
        set {
            if( selectedTab == null || saveData() == true ) {
                selectedTab = value;
            }
        }
    }
    public String pageMode { get; set; }

    public ID projectID { get; set; }
    public Daily__c d { get; set; }

    public List<RecordType> dailyRTList { get; set; }
    public ID dailyRTID { get; set; }

    public static Map<String, RecordTypeInfo> dailyRTInfoList = Schema.SObjectType.Daily__c.getRecordTypeInfosByName();
    public ID projRTID {
        get {
            return dailyRTInfoList.get( 'Project' ).getRecordTypeId();
        }
        set;
    }
    public ID projNoMaterialRTList {
        get {
            return dailyRTInfoList.get( 'Project w/Out Material' ).getRecordTypeId();
        }
        set;
    }

    public Boolean noUnit { get; set; }
    public List<Equipment__c> equipList { get; set; }
    public ID selectedUnitID { get; set; }
    public Equipment__c selectedUnit { get; set; }

    // this class allows we to simplify and reuse code to handle all 4 related lists
    // it handles add/delete/edit/cancel/save operations on related records
    // THIS IS TO AVOID HAVING THE SAME METHODS 4 TIMES DOING THE SAME THING ON DIFFERENT OBJECTS

    public class RelatedObjListHandler {
        // map of related records indexed by the record position on the page
        // this needs to use SObject to be generic
        public Map<Integer, SObject> theMap { get; set; }

        // this will be set by the page when a button is clicked
        public Integer selectedIndex { get; set; }

        // this template will be used to create new records
        public SObject recordTemplate;
        public RelatedObjListHandler( Map<Integer, SObject> mapParam, SObject templateParam ) {
            theMap = mapParam;
            recordTemplate = templateParam;
        }

        public Integer addRecord() {
            SObject o = recordTemplate.clone();

            // add object at the end of the map
            theMap.put( theMap.size(), o );

            selectedIndex = theMap.size() - 1;

            // if parent daily id is blank, populate it
            if( selectedRecord.get( parentID ) == null ) {
                selectedRecord.put( parentID, parentIDValue );
            }

            return selectedIndex;
        }

        public Boolean deleteObjFromMap() {
            try {
                // save a clone of the record to be deleted in case the delete fails
                createUndoRecord();

                // deletes record and then removes it from map
                delete selectedRecord;
                theMap.remove( selectedIndex );

                reindexMap();

                selectedIndex = null;

                return true;

            } catch( Exception e ) {
                system.debug( e.getMessage() + ' - ' + e.getStackTraceString() );
                ApexPages.addMessages( e );
            }

            // if delete fails, we need to restore the record to the map
            theMap.put( selectedIndex, clonedRecord );

            return false;
        }

        public void reindexMap() {
            // reindex map so that the keys are 0, 1, 2, ... without gaps
            Map<Integer, SObject> newMap = new Map<Integer, SObject> ();
            Integer i = 0;
            for( SObject o : theMap.values() ) {
                newMap.put( i, o );
                i ++;
            }

            theMap = newMap;
        }

        SObject clonedRecord;
        public void createUndoRecord() {
            // if parent daily id is blank, populate it
            system.debug( 'parentID ' + parentID + ' = ' + parentIDValue );
            if( parentID != null && parentIDValue != null
                    && selectedRecord.get( parentID ) == null ) {
                selectedRecord.put( parentID, parentIDValue );
            }

            clonedRecord = selectedRecord.clone( true );
        }

        public Boolean saveRecord() {
            try {
                // if parent daily id is blank, populate it
                if( parentID != null && parentIDValue != null
                        && selectedRecord.get( parentID ) == null ) {
                    selectedRecord.put( parentID, parentIDValue );
                }

                upsert selectedRecord;
                selectedIndex = null;
                return true;

            } catch( Exception e ) {
                system.debug( e.getMessage() + ' - ' + e.getStackTraceString() );
                ApexPages.addMessages( e );
            }

            return false;
        }

        public void cancelRecord() {
            if( selectedRecord.ID == null ) {
                theMap.remove( selectedIndex );

            } else {
                // recover original copy of the record (undo)
                theMap.put( selectedIndex, clonedRecord );
            }

            selectedIndex = null;
        }

        public Set<Integer> indexSet {
            get {
                if (theMap == null) {
                    return new Set<Integer>();
                }
                return theMap.keySet();
            }
            set;
        }

        public SObject selectedRecord {
            get {
                return theMap.get( selectedIndex );
            }
            set;
        }

        public String parentID;
        public String parentIDValue;

        public void setParentID( String colName, String colValue ) {
            parentID = colName;
            parentIDValue = colValue;
        }
    }

    // this map will store an instance of the RelatedObjListHandler for each of the 4 related lists
    // the same class methods will handle all 4 related lists
    // each button (add,delete,edit,save,cancel) on the page will set the selectedObj to the index that corresponds to
    // the apropriate RelatedObjListHandler in the map
    // THIS AVOIDS HAVING TO COPY THE SAME METHODS 4 TIMES TO DO THE SAME THING ON DIFFERENT OBJECTS
    public Map<String, RelatedObjListHandler> relatedObjMap { get; set; }
    public String selectedObj { get; set; }

    public VFC_PageWithReltatedObjectTabs( ApexPages.StandardController controller ) {
        if( ! Test.isRunningTest() ) {
            controller.addFields( new List<String> { 'Arrival_Time__c', 'Category__c', 'Click_Pounds__c'
                    , 'Counter_1_Start__c', 'Counter_1_Stop__c', 'Counter_2_Start__c', 'Counter_2_Stop__c'
                    , 'County__c', 'CreatedById', 'Name', 'Daily_Unique_ID__c', 'Departure_Time__c'
                    , 'Enter_Your_Own_Safety_Topic__c', 'Entry_Date__c', 'Equipment__c', 'Foam_Density__c'
                    , 'Inspector_Turned_in_Method__c', 'Is_Clicks_Meter_Operational__c'
                    , 'Is_Flow_Meter_Gallons_Operational__c', 'Is_Flow_Meter_Pounds_Operational__c'
                    , 'Is_Project_Complete__c', 'ISO_1_Liters_After_Shift__c', 'ISO_1_Liters_Before_Shift__c'
                    , 'ISO_2_Liters_After_Shift__c', 'ISO_2_Liters_Before_Shift__c', 'ISO_Gallons__c', 'ISO_LBS__c'
                    , 'ISO_Lot__c', 'ISO_Meter_Start__c', 'ISO_Meter_Stop__c', 'Job_Location__c', 'LastModifiedById'
                    , 'Manufacturer__c', 'Material_Required__c', 'Messages__c', 'OwnerId', 'Pounds_Turned_In__c'
                    , 'Project__c', 'Project_Billing_Method__c', 'Reaction_Speed__c'
                    , 'Remaining_on_Truck_3_5_Ft__c', 'Remaining_on_Truck_5_Ft__c', 'Remaining_on_Truck_8_Ft__c'
                    , 'Resin_1_Liters_After_Shift__c', 'Resin_1_Liters_Before_Shift__c'
                    , 'Resin_2_Liters_After_Shift__c', 'Resin_2_Liters_Before_Shift__c', 'Resin_Gallons__c'
                    , 'Resin_LBS__c', 'Resin_Lot__c', 'Resin_Meter_Start__c', 'Resin_Meter_Stop__c'
                    , 'Resin_to_ISO_Ratio__c', 'Safety_Meeting_Discussion__c', 'Safety_Topic_Weekly__c'
                    , 'Sequence__c', 'Status__c', 'Total_Clicks__c', 'Total_Crew_Records__c'
                    , 'Total_Daily_Location_Pounds__c', 'Total_Flow_Meter_LBS__c', 'Total_LBs_Used_on_this_Daily__c'
                    , 'Total_Location_LBS__c', 'Total_Location_Records__c', 'Total_Project_LBs_Remaining__c'
                    , 'Total_Project_LBs_Sold__c', 'Total_Time_Hours__c', 'Transferred_FROM_Yard_or_Unit__c'
                    , 'Transferred_TO_Yard_or_Unit__c', 'Tubing_3_5_Ft__c', 'Tubing_5_Ft__c', 'Tubing_8_Ft__c'
                    , 'Unit__c', 'Unit_Factor__c', 'Warranty_Work__c', 'Were_Numbers_Turned_in_to_the_Inspector__c'
                    , 'Why_No_Numbers_Turned_In__c', 'Work_Date__c', 'Work_Description__c', 'Unit__r.Name'
                    , 'Project__r.Project_Number__c', 'RecordTypeId' } );
        }
        d = (Daily__c) controller.getRecord();

        system.debug( d.RecordTypeID );

        initialize();
    }

    public void initialize() {
        system.debug( ApexPages.currentPage().getParameters() );

        selectedTab = tabList[ 0 ];
        pageMode = 'DAILY';
        noUnit = false;

        Map<String, RecordTypeInfo> dailyRTInfoList = Schema.SObjectType.Daily__c.getRecordTypeInfosByName();
        projRTID = dailyRTInfoList.get( 'Project' ).getRecordTypeId();
        projNoMaterialRTList = dailyRTInfoList.get( 'Project w/Out Material' ).getRecordTypeId();

        // prompt record type selection if needed
        if( d == null || ( d.ID == null && d.RecordTypeID == null ) ) {
            pageMode = 'RECORDTYPES';
            promptRecordTypeSelection();
            return;
        }

        // prompt unit/equipment selection if needed
        if( d != null && d.ID == null && d.RecordTypeID != projNoMaterialRTList ) {
            retrieveEquipment();
            return;
        }

        initializeDaily();

        if( d.ID != null ) {
            retrieveRelatedRecords();
        }

        system.debug( 'pageMode= ' + pageMode );
    }

    public void promptRecordTypeSelection() {
        d = new Daily__c();

        projectID = ApexPages.currentPage().getParameters().get( 'ProjectID' );

        // TODO:  see if it is still necessary to prompt record types
        String rtQuery = 'SELECT ID, Name, DeveloperName, Description '
                + 'FROM RecordType '
                + 'WHERE SobjectType = \'Daily__c\' ';

        if( projectID != null ) {
            d.Project__c = projectID;

            rtQuery = rtQuery + 'AND Name LIKE \'Project%\' ';

        }

        dailyRTList = Database.query( rtQuery );

        // this flow will continue when user clicks to selectRecordType()
        system.debug( 'prompting for record type selection' );
    }

    public void retrieveEquipment() {
        equipList =
                [ SELECT ID, Name, Model__c, Type__c, Equipment_Description__c
                FROM Equipment__c
                WHERE Status__c = 'Active'
                AND RecordType.Name = 'Pumping Unit'
                ORDER BY Name ];
        system.debug( 'prompting for equipment selection= ' + equipList );
        pageMode = 'UNITS';
    }

    public void selectRecordType() {
        system.debug( 'dailyRTID= ' + dailyRTID );

        Map<ID, RecordType> rtMap = new Map<ID, RecordType>( dailyRTList );
        RecordType rt = rtMap.get( dailyRTID );

        if( rt != null && rt.Name.containsIgnoreCase( 'w/Out Material' ) ) {
            system.debug( 'skipping prompt for Unit selection' );
            // if no Material then there is no Unit needed
            pageMode = 'DAILY';
            return;

        }

        // prompt for unit/equipment selection
        system.debug( 'prompting for Unit selection' );

        retrieveEquipment();

        d.RecordTypeId = dailyRTID;

        // this flow will continue when user clicks to selectUnit()
    }

    public void selectUnit() {
        system.debug( 'selectedUnitID= ' + selectedUnitID );

        Map<ID, Equipment__c> equipMap = new Map<ID, Equipment__c>( equipList );
        selectedUnit = equipMap.get( selectedUnitID );

        //d = new Daily__c();
        d.Unit__c = selectedUnitID;
        d.Project__c = projectID;
        d.Status__c = 'New';
        d.Entry_Date__c = Date.today();
        d.Work_Date__c = Date.today();

        initializeDaily();

        // copy data from previous daily
        copyPreviousDaily();

        // this should bring formula values that depend on Unit__c
        d.recalculateFormulas();

        pageMode = 'DAILY';
    }

    public void initializeDaily() {
        selectedUnitID = d.Unit__c;
        selectedUnit = d.Unit__r;

        if( d.Work_Date__c == null && d.Entry_Date__c != null ) {
            d.Work_Date__c = d.Entry_Date__c;
        }

        dailyRTID = d.RecordTypeId;
        system.debug( 'dailyRTID= ' + dailyRTID );
        system.debug( 'projRTID= ' + projRTID );
        system.debug( 'projNoMaterialRTList= ' + projNoMaterialRTList );

        relatedObjMap = new Map<String, RelatedObjListHandler>();

        Daily_Equipment__c templateEquipment = new Daily_Equipment__c();
        templateEquipment.Daily__c = d.ID;
        relatedObjMap.put( 'Equipment', new RelatedObjListHandler( new Map<Integer, SObject>(), templateEquipment ) );

        Daily_Location__c templateLocation = new Daily_Location__c();
        templateLocation.Daily__c = d.ID;
        relatedObjMap.put( 'Locations', new RelatedObjListHandler( new Map<Integer, SObject>(), templateLocation ) );

        Daily_Crew__c templateCrew = new Daily_Crew__c();
        templateCrew.Daily__c = d.ID;
        relatedObjMap.put( 'Crew', new RelatedObjListHandler( new Map<Integer, SObject>(), templateCrew ) );

        Daily_Sub_Contractor__c templateSubContractor = new Daily_Sub_Contractor__c();
        templateSubContractor.Daily__c = d.ID;
        relatedObjMap.put( 'SubContractor', new RelatedObjListHandler( new Map<Integer, SObject>(), templateSubContractor ) );
    }

    public void retrieveRelatedRecords() {
        // retrieve and store each related list into the map of RelatedObjListHandler so
        // that it will handle add/delete/edit/cancel/save operations on related records

        // retrieve and index daily locations
        List<Daily_Location__c> dailyLocationList =
                [ SELECT ID, Name, Beginning_Location__c, Comments__c, CreatedById, Daily__c, Ending_Location__c
                        , Flows_Clicks__c, Holes_Injected_1__c, Holes_Injected_2__c, Holes_Injected_3__c
                        , Holes_Injected_4__c, Holes_Injected_5__c, Holes_Injected_6__c, Inj_Depth_1_In_Feet__c
                        , Inj_Depth_2_in_Feet__c, Inj_Depth_3_in_Feet__c, Inj_Depth_4_In_Feet__c
                        , Inj_Depth_5_In_Feet__c, Inj_Depth_6_In_Feet__c, LastModifiedById, Lbs_1__c
                        , Lbs_2__c, Lbs_3__c, Lbs_4__c, Lbs_5__c, Lbs_6__c, Length_in_Feet__c, Lift_in_Inches__c
                        , Pounds__c, Street__c, Total_Holes_Drilled__c, Total_Holes_Injected__c
                        , Total_Pounds_Used__c, Width_in_Feet__c
                        , Beginning_Location__latitude__s, Ending_Location__latitude__s
                        , Beginning_Location__longitude__s, Ending_Location__longitude__s
                FROM Daily_Location__c
                WHERE Daily__c = :d.ID ];

        Map<Integer, SObject> locationsMap = getIndexedMapFromList( dailyLocationList );

        Daily_Location__c template = new Daily_Location__c();
        template.Daily__c = d.ID;
        relatedObjMap.put( 'Locations', new RelatedObjListHandler( locationsMap, template ) );


        // retrieve and index daily crews
        List<Daily_Crew__c> dailyCrewList =
                [ SELECT ID, Name, Daily__c, Employee__c, Position__c
                        , On_The_Clock_Start_Time__c, Off_The_Clock_Stop_Time__c
                        , Certified_Start_Time__c, Certified_Stop_Time__c
                        , Lunch_Start_Time__c, Lunch_Stop_Time__c
                        , Misc_Time_Hours__c, Misc_Time_Description__c, Travel_Mode__c, Per_Diem__c
                        , Out_of_Time__c, Attended_Safety_Meeting__c
                FROM Daily_Crew__c
                WHERE Daily__c = :d.ID ];

        Map<Integer, SObject> crewMap = getIndexedMapFromList( dailyCrewList );

        Daily_Crew__c templateCrew = new Daily_Crew__c();
        templateCrew.Daily__c = d.ID;
        relatedObjMap.put( 'Crew', new RelatedObjListHandler( crewMap, templateCrew ) );


        // retrieve and index daily equipment
        List<Daily_Equipment__c> dailyEquipmentList =
                [ SELECT ID, Name, Daily__c, Equipment__c, Issue_with_Equipment__c, Issue__c, Comments__c
                FROM Daily_Equipment__c
                WHERE Daily__c = :d.ID ];

        Map<Integer, SObject> equipmentMap = getIndexedMapFromList( dailyEquipmentList );

        Daily_Equipment__c templateEquipment = new Daily_Equipment__c();
        templateEquipment.Daily__c = d.ID;
        relatedObjMap.put( 'Equipment', new RelatedObjListHandler( equipmentMap, templateEquipment ) );


        // retrieve and index daily sub-contractor
        List<Daily_Sub_Contractor__c> dailySubContractorList =
                [ SELECT ID, Name, Daily__c, Project_Sub_Contractor__c, Quantity_Applied_Today__c
                        , Comments__c, Complete__c
                FROM Daily_Sub_Contractor__c
                WHERE Daily__c = :d.ID ];

        Map<Integer, SObject> subContractorMap = getIndexedMapFromList( dailySubContractorList );

        Daily_Sub_Contractor__c templateSubContractor = new Daily_Sub_Contractor__c();
        templateEquipment.Daily__c = d.ID;
        relatedObjMap.put( 'SubContractor', new RelatedObjListHandler( subContractorMap, templateSubContractor ) );
    }

    public Map<Integer, SObject> getIndexedMapFromList( List<SObject> objList ) {
        Map<Integer, SObject> indexedMap = new Map<Integer, SObject>();
        for( SObject s : objList ) {
            Integer newIndex = indexedMap.size();
            indexedMap.put( newIndex, s );
        }

        return indexedMap;
    }

    public void copyPreviousDaily() {
        // only copy if new daily
        if( d.ID != null ) {
            return;
        }

        // Most recently daily within the last 7 days entered by the Same Supervisor for the same Project
        // copy Daily Equipment, Daily Crew and auto fill the Unit
        system.debug( 'retrieving previous daily for project ID= ' + projectID
                    + ' and Unit= ' + d.Unit__c + ' and RecordType= ' + d.RecordTypeId );
        List<Daily__c> previousDailyList =
                [ SELECT ID, Project__c, Unit__c, County__c, Warranty_Work__c
                    , ( SELECT ID, Name, Daily__c, Equipment__c, Issue__c, Issue_with_Equipment__c, Comments__c
                        FROM Daily_Equipment__r )
                    , ( SELECT ID, Name, Daily__c, Employee__c, Attended_Safety_Meeting__c
                            , Certified_Start_Time__c, Certified_Stop_Time__c
                            , Lunch_Start_Time__c, Lunch_Stop_Time__c, Misc_Time_Hours__c, Misc_Time_Description__c
                            , Off_The_Clock_Stop_Time__c, On_The_Clock_Start_Time__c
                            , Out_of_Time__c, Per_Diem__c, Position__c, Travel_Mode__c
                        FROM Daily_Crew__r )
                FROM Daily__c
                WHERE Project__c = :projectID
                    AND OwnerID = :UserInfo.getUserId()
                    AND CreatedDate >= LAST_N_DAYS:7
                    AND Unit__c = :d.Unit__c
                    AND RecordTypeId = :d.RecordTypeId
                ORDER BY CreatedDate DESC
                LIMIT 1 ];

        if( previousDailyList.size() <= 0 ) {
            return;
        }

        Daily__c previousDaily = previousDailyList[ 0 ];

        d.County__c = previousDaily.County__c;
        d.Warranty_Work__c = previousDaily.Warranty_Work__c;

        // copy related records equipments/crews to indexed maps and unlink them from previous daily
        List<Daily_Equipment__c> dailyEquipmentList = previousDaily.Daily_Equipment__r;
        system.debug( 'dailyEquipmentList= ' + dailyEquipmentList );
        for( Daily_Equipment__c e : dailyEquipmentList ) {
            e.ID = null;
            e.Daily__c = null;
        }

        // store in related object list
        Map<Integer, SObject> equipmentMap = getIndexedMapFromList( dailyEquipmentList );
        Daily_Equipment__c templateEquipment = new Daily_Equipment__c();
        templateEquipment.Daily__c = d.ID;
        relatedObjMap.put( 'Equipment', new RelatedObjListHandler( equipmentMap, templateEquipment ) );

        List<Daily_Crew__c> dailyCrewList = previousDaily.Daily_Crew__r;
        system.debug( 'dailyCrewList= ' + dailyCrewList );
        for( Daily_Crew__c c : dailyCrewList ) {
            c.ID = null;
            c.Daily__c = null;
        }

        // store in related object list
        Map<Integer, SObject> crewMap = getIndexedMapFromList( dailyCrewList );
        Daily_Crew__c templateCrew = new Daily_Crew__c();
        templateCrew.Daily__c = d.ID;
        relatedObjMap.put( 'Crew', new RelatedObjListHandler( crewMap, templateCrew ) );
    }

    // handle CRUD operations on related lists Location, Equipment, Crew and Sub-Contractor

    public void addRecord() {
        system.debug( 'addRecord ' + selectedObj );

        relatedObjMap.get( selectedObj ).setParentID( 'Daily__c', d.ID );
        relatedObjMap.get( selectedObj ).addRecord();
    }
    public void deleteRecord() {
        system.debug( 'selectedObj= ' + selectedObj );
        system.debug( 'selectedIndex= ' + relatedObjMap.get( selectedObj ).selectedIndex );

        relatedObjMap.get( selectedObj ).deleteObjFromMap();
    }
    public void editRecord() {
        system.debug( 'selectedObj= ' + selectedObj );
        system.debug( 'selectedIndex= ' + relatedObjMap.get( selectedObj ).selectedIndex );

        relatedObjMap.get( selectedObj ).setParentID( 'Daily__c', d.ID );
        relatedObjMap.get( selectedObj ).createUndoRecord();
    }
    public void saveRecord() {
        relatedObjMap.get( selectedObj ).setParentID( 'Daily__c', d.ID );

        if( validateRelatedObjects() == false ) {
            return;
        }

        relatedObjMap.get( selectedObj ).saveRecord();
    }
    public void cancelRecord() {
        relatedObjMap.get( selectedObj ).cancelRecord();
    }
    public void saveAndNewRecord() {
        relatedObjMap.get( selectedObj ).setParentID( 'Daily__c', d.ID );

        if( validateRelatedObjects() == false ) {
            return;
        }

        if( relatedObjMap.get( selectedObj ).saveRecord() == false ) {
            return;
        }

        relatedObjMap.get( selectedObj ).addRecord();
    }

    ///

    public Boolean validateRelatedObjects() {

        // get related records list
        RelatedObjListHandler rolh = relatedObjMap.get( selectedObj );

        // validate each record
        for( Integer i : rolh.indexSet ) {
            // get a record
            SObject s = rolh.theMap.get( i );

            // validate locations
            if( selectedObj == 'Locations' ) {

                // validate all 5 pairs of injection depth/pounds fields
                for( Integer j = 1; j < 5; j++ ) {
                    if( areInjectionDepthAndPoundsValid( s, j ) == false ) {
                        ApexPages.addMessage( new ApexPages.Message(
                                    ApexPages.Severity.ERROR, 'Pounds pumped is required for hole #' + j ) );
                        return false;
                    }
                }
            }

            // validate locations
            if( selectedObj == 'Locations' ) {

                // validate all 5 pairs of injection depth/pounds fields
                for( Integer j = 1; j < 5; j++ ) {
                    if( areInjectionDepthAndPoundsValid( s, j ) == false ) {
                        ApexPages.addMessage( new ApexPages.Message(
                                ApexPages.Severity.ERROR, 'Pounds pumped is required for hole #' + j ) );
                        return false;
                    }
                }
            }
        }

        return true;
    }

    public Boolean areInjectionDepthAndPoundsValid( SObject s, Integer i ) {
        String index = String.valueOf( i );
        String injectionDepthColumn = 'Inj_Depth_1_In_Feet__c';
        injectionDepthColumn = injectionDepthColumn.replace( '1', index );

        String injectionPoundsColumn = 'Lbs_1__c';
        injectionPoundsColumn = injectionPoundsColumn.replace( '1', index );

        if( (Decimal) s.get( injectionDepthColumn ) > 0 ) {
            if( s.get( injectionPoundsColumn ) == null || (Decimal) s.get( injectionPoundsColumn ) <= 0 ) {
                return false;
            }
        }

        return true;
    }

    public Boolean validateDaily() {
        // this doesn't work - error: Unable to create/update fields: Name, CreatedById, LastModifiedById
        //d.recalculateFormulas();

        if( d.Resin_to_ISO_Ratio__c != null && d.Resin_to_ISO_Ratio__c <= 0.955 ) {
            ApexPages.addMessage( new ApexPages.Message(
                    ApexPages.Severity.WARNING, 'WARNING... ISO RICH!' ) );

        }
        if( d.Resin_to_ISO_Ratio__c != null && d.Resin_to_ISO_Ratio__c >= 1.045 ) {
            ApexPages.addMessage( new ApexPages.Message(
                    ApexPages.Severity.WARNING, 'WARNING... RESIN RICH!' ) );

        }

        return true;
    }

    public PageReference previous() {
        Integer selectedTabIndex = tabList.indexOf( selectedTab );
        if( selectedTabIndex < 1 ) {
            return null;
        }

        // save current tab data before switching
        saveData();

        if( areThereErrors() == true ) {
            return null;
        }

        selectedTab = tabList[ selectedTabIndex - 1 ];
        system.debug( 'selectedTab= ' + selectedTab );

        return null;
    }

    public PageReference next() {
        // save current tab data before switching
        saveData();

        if( areThereErrors() == true ) {
            return null;
        }

        // if already on the last tab, redirect to record page
        Integer selectedTabIndex = tabList.indexOf( selectedTab );
        if( selectedTabIndex >= tabList.size() - 1 ) {
            ApexPages.StandardController sc = new ApexPages.StandardController( (SObject) d );
            PageReference pr = sc.view();
            return pr;
        }

        selectedTab = tabList[ selectedTabIndex + 1 ];
        system.debug( 'newly selectedTab= ' + selectedTab );

        return null;
    }

    public Boolean areThereErrors() {
        if( ApexPages.getMessages().size() <= 0 ) {
            return false;
        }

        for( ApexPages.Message m : ApexPages.getMessages() ) {
            if( m.getSeverity() == ApexPages.Severity.ERROR ) {
                // yes, there are errors
                return true;
            }
        }

        // only warnings
        return false;
    }

    public Boolean saveData() {
        system.debug( 'saveData()' );

        try {

            if( validateDaily() == false ) {
                return false;
            }

            if( d.Daily_Unique_ID__c == null ) {
                Date theDate = d.Work_Date__c;
                if( theDate == null ) {
                    theDate = d.Entry_Date__c;
                }

                // check if daily is for project
                String projNumber;
                if( d.Project__c != null
                    && ( d.RecordTypeId == projRTID || d.RecordTypeId == projNoMaterialRTList ) ) {
                    // retrieve parent project number
                    List<Project__c> projList =
                            [ SELECT ID, Project_Number__c
                            FROM Project__c
                            WHERE ID = :d.Project__c ];

                    if( projList.size() > 0 ) {
                        projNumber = projList[ 0 ].Project_Number__c;
                    }
                }

                // get latest sequence number
                List<Daily__c> lastDailyList =
                        [ SELECT ID, Sequence__c
                        FROM Daily__c
                        WHERE OwnerID = :UserInfo.getUserId()
                            AND RecordTypeId = :d.RecordTypeId
                            AND Work_Date__c = :theDate
                        ORDER BY Sequence__c DESC
                        LIMIT 1 ];
                String theSeq = '1';
                if( lastDailyList.size() > 0 ) {
                    theSeq = String.valueOf( Integer.valueOf( lastDailyList[ 0 ].Sequence__c  ) + 1 );
                }

                d.Sequence__c = theSeq;
                d.Daily_Unique_ID__c = ( projNumber != null ? projNumber + '-' : '' ) + UserInfo.getName()
                                    + '-' + theDate.format() + '-' + theSeq;
            }

            system.debug( 'upserting ' + d );

            upsert d;

            system.debug( d.ID );

            // verify that related records and save if needed
            String[] relatedObjectList = new String[] { 'Locations', 'Equipment', 'Crew', 'SubContractor' };
            for( String relatedObject : relatedObjectList ) {
                RelatedObjListHandler rolh = relatedObjMap.get( relatedObject );

                // for each related object, check each record id
                for( Integer i : rolh.indexSet ) {
                    // get a record
                    SObject s = rolh.theMap.get( i );
                    if( s.ID != null ) {
                        continue;
                    }

                    // if ID is blank, assign to parent daily and save it
                    rolh.setParentID( 'Daily__c', d.ID );
                    rolh.selectedIndex = i;
                    if( rolh.saveRecord() == false ) {
                        return false;
                    }
                }
            }

            return true;

        } catch( Exception e ) {
            system.debug( e.getMessage() + ' - ' + e.getStackTraceString() );
            ApexPages.addMessages( e );
        }

        return false;
    }
}