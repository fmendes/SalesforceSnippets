/**************************************************************************************************************************
* Purpose: This Class is to used by the "GoNearbyAccounts" VisualForce Page to show the current Accounts location on a Map
***************************************************************************************************************************/

public without sharing class VFC_GeoNearbyAccounts {

        /**************************************************************************************
        * Setup Variables for storing data required to show Acounts onto a Map
        ***************************************************************************************/

    // Create and initialize the variables below for storing current information on current and nearby accounts
    public List<NearbyAccount> nearbyAccounts;
    private Account currentAccount;
    public Map<String,String> filterCriteriaMap;

    public String distance {get;set;}                   // Stores the filter criteria to show the distance scale that should be shown on the map
    public Integer vZoomLevels {get;set;}               // This is the zoom level for the Map according to the distance in Miles on the map to help scaling

    public Account filterAccount {get;set;}             // Temporary storing of filter account information
    public String filterFields {get;set;}       // Store the Filter criteria into this string and pass to the generic controller for filtering

    // This method will pull the details of the currently opened account in Salesforce
    // Constructor for initializing and pulling back data to display
    public VFC_GeoNearbyAccounts(ApexPages.StandardController controller)
    {
        // Create new Account object and assign default values on page load
        filterAccount = new Account();
        //filterAccount.Type ='--None--';

        distance = '2';   // Default Scale on Map Set to 1 Miles
        vZoomLevels = 14;

        // Pull back the current Account Id from the Page and query for the current Account Co-ordinates
        if(controller.getRecord() != null && controller.getRecord().Id != null)
        {
            // Query and pull back current Account Details
            currentAccount = [SELECT Id, Name, Phone, ParentId, Parent.Name,
                    BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode,
                    BillingLatitude, BillingLongitude
            FROM Account
            WHERE Id = :controller.getRecord().Id];
        }
    }


    // This method is used to pull back all nearby Accounts using the criteria in the filtering fields on the page
    // E.g. Distance/ Industry / Type
    public List<Account> getNearby(Account a)
    {
        // Store the Nearby Accounts into this list so we can display this onto the screen
        List<Account> nearby = new List<Account>();

        if(a == null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'No account selected'));
            return nearby;
        }

        system.debug('***** filterFields :'+filterFields);              // Display the filter fields when debugging

        // This section of the code pulls back the criteria for filtering on the VF Map page, it then splits the values so we can query for
        // accounts that are nearby
        String whereClause = '';
        if(filterFields != null)
        {
            List<String> fieldNames = filterFields.split(':');
            for(String fName : fieldNames)
            {
                try
                {
                    String value = (String)((SObject)filterAccount).get(fName);
                    if(value != null)
                    {
                        whereClause += ' AND ' + fName + ' = \'' + value + '\'';
                    }
                }
                catch (Exception exp)
                {
                    //Field Not Found
                    // If the field is not found then throw this error onto the screen
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Filter Field Not Found ' + fName));
                }
            }
        }

        // If no distance is set, such as on page load. What should the default setting be for displaying the Map. 1 = 1 Mile
        if(distance == null) distance = '2';
        Integer distanceInt = Integer.valueOf(distance);
        //if(distanceInt == null || distanceInt < 5) distanceInt = 5;

        // Once we have all of the filter criteria set, we need to run the query and pull back all of the nearby accounts
        // Using the latitude and longitude coordinates
        if(a.BillingLatitude != null && a.BillingLongitude != null)
        {
            String qry = 'SELECT Id, Name, ParentId, Parent.Name, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, BillingLatitude, BillingLongitude';
            qry += ' FROM Account';
            qry += ' WHERE';
            if(!Test.isRunningTest()) qry += ' DISTANCE(BillingAddress, GEOLOCATION(' + a.BillingLatitude + ', ' + a.BillingLongitude + '), \'mi\') < ' + distanceInt + ' AND ';
            qry += ' Id <> \'' + a.Id + '\'';
            if(whereClause != null && whereClause != '') qry += whereClause;
            if(!Test.isRunningTest()) qry += ' ORDER BY DISTANCE(BillingAddress, GEOLOCATION(' + a.BillingLatitude + ', ' + a.BillingLongitude + '), \'mi\')';

            system.debug ('***** qry :'+qry);

            System.debug(qry);
            //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, qry));
            nearby = Database.query(qry);
        }
        else
        {
            // This will be displayed if the Accounts have no longitude or latitude coordinates
            // To set the accounts to have Coordinates follow these steps
            // Goto Setup --> Data.com --> Turn on the Auto Cleanse Rule for BillingAddress (this will update all accounts with coordinates with valid addresses)
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'No Lat/Long for Account'));
        }

        // Once all of the Nearby Accounts have been queried, return this list to the calling method
        // Go and set the scale for the map and zoom the map at a given level
        setZoomLevels(distanceInt);

        return nearby;
    }


    public PageReference submit()
    {
        return null;
    }

    // Add any nearby accounts to the nearbyAccounts List collection
    public List<NearbyAccount> getNearbyAccounts()
    {
        nearbyAccounts = new List<NearbyAccount>();
        List<Account> accounts = getNearby(currentAccount);
        for(Account a : accounts)
        {
            nearbyAccounts.add(new NearbyAccount(a.BillingLatitude,a.BillingLongitude,a));
        }
        return nearbyAccounts;
    }

    // Wrapper Class for the Nearby Accounts information, helps to store it's account details and coordinates
    public class NearbyAccount
    {
        public String position {get;set;}
        public Decimal latitude {get;set;}
        public Decimal longitude {get;set;}
        public Account a {get;set;}

        public NearbyAccount(Decimal latitude, Decimal longitude, Account a)
        {
            //{latitude: 37.794, longitude: -122.395}
            position = '{latitude: ' + latitude + ', longitude: ' + longitude + '}';
            this.latitude = latitude;
            this.longitude = longitude;
            this.a = a;
        }
    }

    //Find zoomlevels
    public void setZoomLevels(Integer distanceInt)
    {
        if (distanceInt <= 2) {               // If set to 2 miles then the zoom level is set to 14
            vZoomLevels = 14;
        }
        else if (distanceInt <= 5) {       // If set to 5 miles then the zoom level is set to 11
            vZoomLevels = 11;
        }
        else if (distanceInt <= 20) {
            vZoomLevels = 10;
        }
        else if (distanceInt <= 50) {
            vZoomLevels = 9;
        }
        else {
            vZoomLevels = 11;  // If there are no other options then do this    Approx 5 Miles
        }
    }

}