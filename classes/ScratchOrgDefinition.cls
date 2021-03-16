/**
 * @description this class serves as a DTO for the generation of a Scratch Org Definition (scratch-def.json) file
 * when creating a new Scratch Org.
 */
public with sharing class ScratchOrgDefinition {
    private String orgName;
    private String country;
    private String username;
    private String adminEmail;
    private String edition;
    private String description;
    private Boolean hasSampleData;
    private String language;

    public ScratchOrgDefinition() {
        this.country = DXLabel.DEFAULT_COUNTRY;
        this.adminEmail = UserInfo.getUserEmail();
        this.edition = DXLabel.DEFAULT_EDITION;
        this.hasSampleData = false;
        this.language = DXLabel.DEFAULT_LANGUAGE;
    }

    /**
     * @description this method lists all the available properties of a Scratch Org Definition file.
     *
     * @return a set with all the Scratch Org Definition properties.
     */
    public Set<String> getProperties() {
        Map<String, Object> propertiesMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(this));
        return propertiesMap.keySet();
    }

    /**
     * @description a setter for the orgName private variable.
     *
     * @param orgName is the name that the new Scratch Org will get once created.
     */
    public void setOrgName(String orgName) {
        this.orgName = orgName;
    }

    /**
     * @description a getter for the orgName private variable.
     *
     * @return the name of the Scratch Org.
     */
    public String getOrgName() {
        return this.orgName;
    }

    /**
     * @description a setter for the username private variable.
     *
     * @param username is the username credential that will be used to sign in to the new Scratch Org.
     */
    public void setUsername(String username) {
        this.username = username;
    }

    /**
     * @description a getter for the username private variable.
     *
     * @return the username credential that is used for signing in to the given Scratch Org.
     */
    public String getUsername() {
        return this.username;
    }

    /**
     * @description a setter for the country private variable.
     *
     * @param country is the default country that will be set in the new Scratch Org.
     */
    public void setCountry(String country) {
        this.country = country;
    }
    /**
     * @description a getter for the country private variable.
     *
     * @return the default country that was set in the given Scratch Org.
     */
    public String getCountry() {
        return this.country;
    }

    /**
     * @description a setter for the adminEmail private variable.
     *
     * @param adminEmail is the default email address to which notifications from the new Scratch Org will be sent.
     */
    public void setAdminEmail(String adminEmail) {
        this.adminEmail = adminEmail;
    }

    /**
     * @description a getter for the adminEmail private variable.
     *
     * @return the default email address that was set in the given Scratch Org for notification purposes.
     */
    public String getAdminEmail() {
        return this.adminEmail;
    }

    /**
     * @description a setter for the edition private variable.
     *
     * @param edition is the Org Edition (Developer/Production/etc) that allows the user to emulate different features
     * and preferences in a brand new Scratch Org.
     */
    public void setEdition(String edition) {
        this.edition = edition;
    }

    /**
     * @description a getter for the edition private variable.
     *
     * @return the edition of a given Scratch Org.
     */
    public String getEdition() {
        return this.edition;
    }

    /**
     * @description a setter for the description private variable.
     *
     * @param description is the additional information about a new Scratch Org  that can be optionally added
     * to the org definition file.
     */
    public void setDescription(String description) {
        this.description = description;
    }

    /**
     * @description a getter for the description private variable.
     *
     * @return the description of the current Scratch Org.
     */
    public String getDescription() {
        return this.description;
    }

    /**
     * @description a setter for the hasSampleData private variable.
     *
     * @param hasSampleData is a flag indicating whether the given org definition file will include sample data to be
     * loaded into the new Scratch Org.
     */
    public void setHasSampleData(Boolean hasSampleData) {
        this.hasSampleData = hasSampleData;
    }

    /**
     * @description a getter for the hasSampleData private variable.
     *
     * @return a flag indicating whether the given Scratch Org had sample data loaded into it after creation.
     */
    public Boolean getHasSampleData() {
        return this.hasSampleData;
    }

    /**
     * @description a setter for the language private variable.
     *
     * @param language is the default language that will be set in the new Scratch Org.
     */
    public void setLanguage(String language) {
        this.language = language;
    }

    /**
     * @description a getter for the language private variable.
     *
     * @return the default language of a given Scratch Org.
     */
    public String getLanguage() {
        return this.language;
    }
}