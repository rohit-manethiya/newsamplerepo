public with sharing class EditGit {
    // Non Constants
    public Git_Repository__c git { get; set; }
    public Boolean keyVisible { get; set; }
    public Boolean isSSHauthentication { get; set; }
    public Boolean hasKeys { get; set; }
    public String selectedKeyId { get; set; }
    public String selectedKeyContent { get; set; }
    public List<GitHelper.ACommit> commits;
    public Boolean showOtherInformation { get; set; }
    public Boolean isShareable { get; set; }
    public List<Attachment> attachments { get; set; }
    public Boolean showError { get; set; }
    public Boolean showOptions { get; set; }
    private Id currentId;
    public String c_username { get; set; }
    public String c_password { get; set; }
    public String authTypeValue { get; set; }
    public String extraHeaders { get; set; }

    // Constants
    public final String KEYNAME = 'id_rsa.pub';
    private final String HTTPS_STRING = 'https';
    private final String SSH_STRING = 'ssh';
    private final String EXTRA_HEADERS = 'Extra Headers';
    private final String BRANCH_BASE_URL = 'https://{0}/(Username)/(RepositoryName)/{1}/';
    private final String COMMIT_BASE_URL = 'https://{0}/(Username)/(RepositoryName)/commit/';
    private final String PR_BASE_URL = 'https://{0}/(Username)/(RepositoryName)/';
    private final String TAG_BASE_URL = 'https://{0}/(Username)/(RepositoryName)/{1}/';
    private final String VS_BRANCH_BASE_URL = 'https://(Username).{0}/_git/(RepositoryName)/{1}/';
    private final String VS_COMMIT_BASE_URL = 'https://(Username).{0}/_git/(RepositoryName)/';
    private final String VS_PR_BASE_URL = 'https://(Username).{0}/_git/(RepositoryName)/';
    private final String VS_TAG_BASE_URL = 'https://(Username).{0}/_git/(RepositoryName)/{1}/';
    private final String GITHUB_COM = 'github.com';
    private final String BITBUCKET_ORG = 'bitbucket.org';
    private final String GITLAB_COM = 'gitlab.com';
    private final String VISUALSTUDIO_COM = 'visualstudio.com';
    private final String BITBUCKET_PROVIDER = 'Bitbucket';
    private final String MTS_PROVIDER = 'Microsoft Team Service';

    public EditGit(ApexPages.StandardController std) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if(!Test.isRunningTest()) {
            std.addFields(new List<String>(Schema.SObjectType.Git_Repository__c.fields.getMap().keySet()));
        }

        showOptions = true;
        showError = false;
        isLicenseEnabled();
        showOtherInformation = SObjectType.Git_Repository__c.fieldSets.CustomFields.getFields().size() > 0;
        keyVisible = false;
        hasKeys = false;
        isSSHauthentication = false;
        selectedKeyContent = '';
        c_username = '';
        c_password = '';

        System.debug('**f**std.getId() : ' + std.getId());
        if(std.getId() != null) {
            git = Utilities.getGitById(std.getId());
            currentId = git.Id;
            Sensitive_Information__c gitRepositoryConfiguration = Sensitive_Information__c.getValues(currentId);
            if(gitRepositoryConfiguration != null) {
                if(String.isNotBlank(gitRepositoryConfiguration.Username__c)) {
                    c_username = gitRepositoryConfiguration.Username__c;
                }
                if(!git.URI__c.startsWith(HTTPS_STRING)) {
                    isSSHauthentication = true;
                    authTypeValue = SSH_STRING;
                    getKeys();
                } else {
                    authTypeValue = HTTPS_STRING;
                    if(Schema.SObjectType.Note.isAccessible() && Schema.SObjectType.Note.isQueryable()) {
                        List<Note> headersList = [SELECT Id, Title, Body FROM Note WHERE ParentId = :git.Id AND Title = :EXTRA_HEADERS];
                        if(!headersList.isEmpty()) {
                            extraHeaders = headersList[0].Body;
                        }
                    } else {
                        UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Note.getLabel());
                    }
                }
            }
        } else {
            git = new Git_Repository__c();
        }

        Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
        isShareable = tokens.containsKey('Git_Repository__Share');
    }

    /**
     * This is used to create or update git repositories.
     * @return return to the standard layout of git repositories.
     */
    public PageReference save() {
        if(String.isBlank(git.Name)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' ' + Schema.SObjectType.Git_Repository__c.fields.Name.getLabel());
            return null;
        }
        if(String.isBlank(git.URI__c)) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' ' + Schema.SObjectType.Git_Repository__c.fields.URI__c.getLabel());
            return null;
        }
        if((authTypeValue == SSH_STRING && git.URI__c.startsWith(HTTPS_STRING)) || (authTypeValue == HTTPS_STRING && !git.URI__c.startsWith(HTTPS_STRING))) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.SSH_URI_validation);
            return null;
        }
        if(authTypeValue == HTTPS_STRING) {
            if(String.isBlank(c_username)) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' ' + Label.USERNAME);
                return null;
            }
            if(String.isBlank(c_password)) {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.Please_Enter + ' ' + Label.PASSWORD);
                return null;
            }
        }
        if(null != currentId && !Utilities.HasEditAccess(currentId)) {
            git.addError(Label.InSuffPriv);
            return null;
        }
        Utilities.Secure_DML(git, Utilities.DML_Action.UPS, schema.SObjectType.Git_Repository__c);

        Sensitive_Information__c gitRepositoryConfiguration = Sensitive_Information__c.getValues(git.Id);
        if(gitRepositoryConfiguration == null) {
            gitRepositoryConfiguration = new Sensitive_Information__c();
            gitRepositoryConfiguration.Name = git.Id;
        }
        if(gitRepositoryConfiguration != null && authTypeValue == HTTPS_STRING) {
            gitRepositoryConfiguration.Username__c = c_username;
            gitRepositoryConfiguration.Password__c = DeployAPI.encryptAPIKey(c_password);
        }

        // protected custom setting so not adding FLS or CRUD
        Utilities.Secure_DML(gitRepositoryConfiguration, Utilities.DML_Action.UPS, schema.SObjectType.Sensitive_Information__c);

        // check extra headers
        if(Schema.SObjectType.Note.isAccessible() && Schema.SObjectType.Note.isQueryable()) {
            List<Note> headersList = [SELECT Id, Title, Body FROM Note WHERE ParentId = :git.Id AND Title = :EXTRA_HEADERS];
            if(String.isNotBlank(extraHeaders)) {
                if(headersList.isEmpty()) {
                    Note newHeaders = new Note(Title = EXTRA_HEADERS, ParentId = git.Id);
                    headersList.add(newHeaders);
                }
                headersList[0].Body = extraHeaders;
                Utilities.Secure_DML(headersList[0], Utilities.DML_Action.UPS, schema.SObjectType.Note);
            } else {
                // if extra headers is blank and there is a note related with git repo then delete the Note record
                if(!headersList.isEmpty()) {
                    Utilities.Secure_DML(headersList[0], Utilities.DML_Action.DEL, schema.SObjectType.Note);
                }
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Note.getLabel());
            return null;
        }

        return new ApexPages.StandardController(git).view();
    }

    /**
     * This is used to validate credential of git repository
     * @return redirect to the git repository standard layout
     */
    public PageReference validate() {
        DeployAPI.validateGitResult validation = DeployAPI.validateGit(git.Id);
        if(validation.success) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.CONFIRM, validation.message);
        } else {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, validation.message);
        }
        return null;
    }

    public void viewKey() {
        if(!String.isBlank(selectedKeyId)) {
            List<Attachment> attList = retrieveAttachments(selectedKeyId, '', '');
            if(!attList.isEmpty()) {
                selectedKeyContent = attList.get(0).Body.toString();
                keyVisible = true;
                selectedKeyId = '';
                return;
            } else {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.Attachment_Could_Not_Be_Found);
            }
        }
    }

    public PageReference deleteKey() {
        try {
            List<Attachment> attList = retrieveAttachments(selectedKeyId, '', '');
            if(!attList.isEmpty()) {
                Utilities.Secure_DML(attList, Utilities.DML_Action.DEL, schema.SObjectType.Attachment);
            } else {
                UIDesignHelper.genericWarningMessage(ApexPages.Severity.ERROR, Label.Attachment_Could_Not_Be_Found);
                return null;
            }
            return new ApexPages.StandardController(git).view();
        } catch(Exception ex) {
            UIDesignHelper.catchExceptionMessage(ex);
            return null;
        }
    }

    /**
     * General private method to retrieve attachment by given parameters
     * @param attId retrieve attachment by Id
     * @param attName retrieve attachment by Name
     * @param parentId retrieve attachment by ParentId
     * @return List of attachments
     */
    private List<Attachment> retrieveAttachments(String attId, String attName, String parentId) {
        List<Attachment> attList = new List<Attachment>();
        if(Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
            if(String.isNotBlank(attId)) {
                attList = [SELECT Body FROM Attachment WHERE Id = :selectedKeyId LIMIT 1];
            } else {
                attList = [SELECT Id, Name, Body, ParentId, CreatedDate, LastModifiedDate FROM Attachment WHERE Name = :attName AND ParentId = :parentId];
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.Attachment.getLabel());
        }
        return attList;
    }

    public PageReference hideSSHkey() {
        return new ApexPages.StandardController(git).view();
    }

    private void getKeys() {
        attachments = new List<Attachment>();
        attachments = retrieveAttachments('', KEYNAME, git.Id);
        hasKeys = attachments.size() == 1 ? true : false;
    }

    /**
     * This is used to create SSH key for git repository
     * @return redirect to the git repository standard layout
     */
    public PageReference createSSHKey() {
        try {
            String result = DeployAPI.createSSHKey(git.Id);
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.INFO, result);
            return new ApexPages.StandardController(git).view();
        } catch(Exception ex) {
            UIDesignHelper.catchExceptionMessage(ex);
            return null;
        }
    }

    public List<GitHelper.ACommit> getCommits() {
        Datetime frm = Datetime.now().addYears(-1);
        return GitHelper.getCommits(git.Id, null, frm.date(), Date.today() + 1, null, null, 10);
    }

    public PageReference deployCommits() {
        PageReference pr = Page.DeployCommits;
        pr.getParameters().put('repositoryId', git.Id);
        return pr;
    }

    public void retrieveCommits() {
        String branch = ApexPages.currentPage().getParameters().get('branch');
        try {
            DeployAPI.getCommitsFromRepo(git.Id, branch);
            ApexPages.getMessages().clear();
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.INFO, Label.COMMITS_BEING_RETRIEVED);
        } catch(Exception ex) {
            UIDesignHelper.catchExceptionMessage(ex);
        }
    }

    public void isLicenseEnabled() {
        if(!LicenseHelper.actionIsLicenseEnabled('viewEditGitRepository')) {
            UIDesignHelper.genericWarningMessage(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('__License__', Label.CCH_License));
            showError = true;
            showOptions = false;
        }
        return;
    }

    public PageReference goToManageGITBranches() {
        PageReference pr = Page.ManageGitBranches;
        pr.getParameters().put('repoId', git.Id);
        pr.setRedirect(true);
        return pr;
    }

    /**
     * This is used to redirect to the object prefix page after record deletion
     * NOTE: We override it because it was failing in lightning (Spring 19)
     *
     * @return object keyprefix page
     */
    public PageReference deleteGitRepository() {
        Utilities.Secure_DML(git, Utilities.DML_Action.DEL, schema.SObjectType.Git_Repository__c);

        Schema.DescribeSObjectResult result = Git_Repository__c.SObjectType.getDescribe();
        PageReference pageRef = new PageReference('/' + result.getKeyPrefix());
        pageRef.setRedirect(true);
        return pageRef;
    }

    /**
     * This is used when user change the Git Provider field at visualforce page. It will populate the URL fields based on selected Git Provider
     */
    public void populateURLFields() {
        if(git.Git_Provider__c != null && git.Git_Provider__c != 'Others') { // Bitbucket, GitLab, Microsoft Team Service, Github
            String branchBaseParameter = git.Git_Provider__c == BITBUCKET_PROVIDER ? 'branch' : 'tree';
            String tagBaseParameter = git.Git_Provider__c == BITBUCKET_PROVIDER ? 'src' : 'tags';
            String branchBaseURLProvider = git.Git_Provider__c == MTS_PROVIDER ? VS_BRANCH_BASE_URL : BRANCH_BASE_URL;
            String commitBaseURLProvider = git.Git_Provider__c == MTS_PROVIDER ? VS_COMMIT_BASE_URL : COMMIT_BASE_URL;
            String prBaseURLProvider = git.Git_Provider__c == MTS_PROVIDER ? VS_PR_BASE_URL : PR_BASE_URL;
            String tagBaseURLProvider = git.Git_Provider__c == MTS_PROVIDER ? VS_TAG_BASE_URL : TAG_BASE_URL;
            String selectedProvider = git.Git_Provider__c == 'Github' ? GITHUB_COM :
                                      git.Git_Provider__c == BITBUCKET_PROVIDER ? BITBUCKET_ORG :
                                      git.Git_Provider__c == 'GitLab' ? GITLAB_COM :
                                      git.Git_Provider__c == MTS_PROVIDER ? VISUALSTUDIO_COM : '';

            // Branch base url
            git.Branch_Base_URL__c = String.format(branchBaseURLProvider, new List<String>{
                selectedProvider, branchBaseParameter
            });
            git.Branch_Base_URL__c = git.Branch_Base_URL__c.replace('(', '{').replace(')', '}');

            // Commit base url
            git.Commit_Base_URL__c = String.format(commitBaseURLProvider, new List<String>{
                selectedProvider
            });
            git.Commit_Base_URL__c = git.Commit_Base_URL__c.replace('(', '{').replace(')', '}');

            // Pr base url
            git.Pull_Request_Base_URL__c = String.format(prBaseURLProvider, new List<String>{
                selectedProvider
            });
            git.Pull_Request_Base_URL__c = git.Pull_Request_Base_URL__c.replace('(', '{').replace(')', '}');

            // Tag base url
            git.Tag_Base_URL__c = String.format(tagBaseURLProvider, new List<String>{
                selectedProvider, tagBaseParameter
            });
            git.Tag_Base_URL__c = git.Tag_Base_URL__c.replace('(', '{').replace(')', '}');
        } else {
            git.Branch_Base_URL__c = null;
            git.Commit_Base_URL__c = null;
            git.Pull_Request_Base_URL__c = null;
            git.Tag_Base_URL__c = null;
        }
    }
}