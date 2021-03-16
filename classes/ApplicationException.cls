public with sharing class ApplicationException extends Exception {
    // PUBLIC

    public void throwAuraHandled() {
        throwAuraHandled(this);
    }

    public void throwAuraHandled(Exception anyException) {
        throw auraHandled(anyException);
    }

    public AuraHandledException auraHandled(Exception anyException) {
        String message = anyException.getMessage();
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}