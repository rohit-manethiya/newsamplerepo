trigger EncodeGitPassword on Git_Repository__c (before insert, before update) {
	// commented out due to security changes related sensitive information in object. password is stored in a protected custom settings right now.
}