public virtual class CliSfDataWrapper {
    public String status;
    public String message;

    public CliSfDataWrapper() {
    }
    
    public CliSfDataWrapper(String stat, String msg) {
        status = stat;
        message = msg;
    }

    public enum StatusResult {
        OK, ERROR
    }
}