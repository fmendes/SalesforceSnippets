public without sharing class Controller_Loan {
    public static String defaultStatus = '10-Received';
    public static String approvalStatus = '50-Approved';
    public static String rejectionStatus = '90-Rejected';

    public Loan__c l { get; set; }
    public List<Loan_Document__c> docList { get; set; }

    public Map<ID, ContentDocument> fileByDocIDMap { get; set; }
    public Map<ID, List<ContentDocument>> fileListByDocIDMap { get; set; }

    public String fileURL { get; set; }
    public String selectedDocID { get; set; }

    public ContentVersion aFile { get; set; }

    public Boolean refreshPage { get; set; }

    public Controller_Loan( ApexPages.StandardController sc ) {
        if( ! Test.isRunningTest() ) {
            sc.addFields( new String[] { 'Name' } );
        }
        l = ( Loan__c ) sc.getRecord();
        initialize();
    }

    public void initialize() {
        refreshPage = false;
        aFile = new ContentVersion();
        selectedDocID = null;
        docList = new List<Loan_Document__c>();

        // identify profile of user running the page
        ID profileID = UserInfo.getProfileId();
        Profile p = [ SELECT ID, Name FROM Profile WHERE ID = :profileID ];
        String profileName = p.Name;

        // retrieve list of documents
        List<Loan_Document__c> originalDocList =
                [ SELECT ID, Name, Document_Type__c, Status__c, Status_Image__c
                        , Loan_Document_Sharing_Capital_Partners__c
                        , Loan_Document_Sharing_Law_Firm__c
                        , Loan_Document_Sharing_Loan_Servicer__c
                        , Loan_Document_Sharing_Senior_Bank__c
                    FROM Loan_Document__c
                    WHERE Loan__c = :l.ID
                    ORDER BY Status__c DESC, Document_Type__c, Name ];

        // filter list by visibility to profile
        for( Loan_Document__c ld : originalDocList ) {
            // skip if profile is one of the 4 below and the loan is not flagged to share with the respective profile
            if( profileName.containsIgnoreCase( 'Capital Partner' )
                    && ld.Loan_Document_Sharing_Capital_Partners__c != 'Yes' ) {
                continue;
            }
            if( profileName.containsIgnoreCase( 'Law Firm' )
                    && ld.Loan_Document_Sharing_Law_Firm__c != 'Yes' ) {
                continue;
            }
            if( profileName.containsIgnoreCase( 'Loan Servicer' )
                    && ld.Loan_Document_Sharing_Loan_Servicer__c != 'Yes' ) {
                continue;
            }
            if( profileName.containsIgnoreCase( 'Bank' )
                    && ld.Loan_Document_Sharing_Senior_Bank__c != 'Yes' ) {
                continue;
            }

            docList.add( ld );
        }

        if( docList.size() > 0 ) {

            // collect doc IDs
            Map<ID, Loan_Document__c> docMap = new Map<ID, Loan_Document__c>( docList );
            Set<ID> docIDSet = docMap.keySet();

            // retrieve files for each document sorted by ContentModifiedDate so that the
            // latest file is assigned to the doc ID
            List<ContentDocumentLink> cdlList =
                    [ SELECT ID, ContentDocumentId, LinkedEntityId
                            , ContentDocument.Title
                            , ContentDocument.ContentModifiedDate
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :docIDSet
                        AND ShareType = 'V'
                    ORDER BY ContentDocument.ContentModifiedDate ];

            // build map of ContentDocument indexed by Loan_Document__c ID
            fileListByDocIDMap = new Map<ID, List<ContentDocument>>();
            fileByDocIDMap = new Map<ID, ContentDocument>();
            for( ContentDocumentLink cdl : cdlList ) {
                ContentDocument cd = new ContentDocument();
                cd.ID = cdl.ContentDocumentId;
                cd.Title = cdl.ContentDocument.Title;

                // add file to the list
                List<ContentDocument> fileList = fileListByDocIDMap.get( cdl.LinkedEntityId );
                if( fileList == null ) {
                    fileList = new List<ContentDocument>();
                }
                fileList.add( cd );
                fileListByDocIDMap.put( cdl.LinkedEntityId, fileList );

                fileByDocIDMap.put( cdl.LinkedEntityId, cd );
            }
        }

        // store placeholders for Loan_Document__c IDs without a file
        ContentDocument cd = new ContentDocument();
        for( Loan_Document__c ld : docList ) {
            if( fileByDocIDMap.containsKey( ld.ID ) == false ) {
                fileByDocIDMap.put( ld.ID, cd );
            }

            if( fileListByDocIDMap.containsKey( ld.ID ) == false ) {
                fileListByDocIDMap.put( ld.ID, new List<ContentDocument> { cd } );
            }
        }

        system.debug( fileByDocIDMap );
        system.debug( fileListByDocIDMap );
    }

    public PageReference promptApproval() {
        system.debug( 'selectedDocID= ' + selectedDocID );
        PageReference pr = Page.LoanDocumentPreview;
        pr.getParameters().put( 'id', selectedDocID );
        pr.getParameters().put( 'retURL', '/' + l.Id );
        pr.setRedirect( true );
        return pr;
    }

    public void approveDoc() {
        system.debug( 'selectedDocID= ' + selectedDocID );

        // get loan doc name
        Map<ID, Loan_Document__c> docMap = new Map<ID, Loan_Document__c> ( docList );
        Loan_Document__c loanDoc = docMap.get( selectedDocID );

        try {
            updateLoanDocStatus( approvalStatus );

        } catch( DMLException e ) {
            reportError( e, loanDoc );
            return;

        } finally {
            initialize();
        }
    }

    public void rejectDoc() {
        system.debug( 'selectedDocID= ' + selectedDocID );

        // get loan doc name
        Map<ID, Loan_Document__c> docMap = new Map<ID, Loan_Document__c> ( docList );
        Loan_Document__c loanDoc = docMap.get( selectedDocID );

        try {
            updateLoanDocStatus( rejectionStatus );

        } catch( DMLException e ) {
            reportError( e, loanDoc );
            return;

        } finally {
            initialize();
        }
    }

    public void updateLoanDocStatus( String theStatus ) {
        SObject doc = Schema.getGlobalDescribe().get( 'Loan_Document__c' ).newSObject();
        doc.ID = selectedDocID;
        doc.put( 'Status__c', theStatus );
        update doc;
    }

    public void uploadFile() {
        system.debug( 'selectedDocID= ' + selectedDocID );
        system.debug( aFile.title );
        system.debug( aFile.VersionData );

        if( selectedDocID == null ) {
            ApexPages.addMessage(new ApexPages.message( ApexPages.severity.ERROR
                    , 'No loan document was assigned for the file.' ) );
            return;
        }

        if( aFile == null || aFile.Title == null ) {
            ApexPages.addMessage(new ApexPages.message( ApexPages.severity.ERROR
                    , 'No file was selected for upload.' ) );
            return;
        }

        // get loan doc name
        Map<ID, Loan_Document__c> docMap = new Map<ID, Loan_Document__c> ( docList );
        Loan_Document__c loanDoc = docMap.get( selectedDocID );

        try {
            // insert content version first, then get content document
            aFile.PathOnClient = '/';
            insert aFile;

            // fetch corresponding content document
            aFile = [ SELECT ID, Title, ContentDocument.ID, ContentDocument.Title
                        FROM ContentVersion
                        WHERE ID= :aFile.ID ];
            ContentDocument cd = aFile.ContentDocument;

            // link file to main record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = selectedDocID;
            cdl.ContentDocumentId = cd.Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;

            // change doc status
            updateLoanDocStatus( defaultStatus );

            String msg = 'Attachment uploaded successfully : ' + aFile.Title;
            if( loanDoc != null ) {
                msg = msg + ' as ' + loanDoc.Name;
            }

            ApexPages.addMessage( new ApexPages.message( ApexPages.severity.INFO, msg ) );

        }catch( DMLException e ) {
            reportError( e, loanDoc );
            return;

        } finally {
            initialize();
        }

        // cause page to do refresh at topmost frame
        refreshPage = true;
    }

    public void cancelFile() {
        aFile = new ContentVersion();
        selectedDocID = null;
    }

    public void reportError( DmlException e, Loan_Document__c loanDoc ) {
        system.debug( e.getMessage() + ' - ' + e.getStackTraceString() );

        String msg = 'Error uploading attachment : ' + aFile.Title;
        if( loanDoc != null ) {
            msg = msg + ' as ' + loanDoc.Name;
        }
        ApexPages.addMessage(new ApexPages.message( ApexPages.severity.ERROR
                , msg ) );
        return;
    }

}