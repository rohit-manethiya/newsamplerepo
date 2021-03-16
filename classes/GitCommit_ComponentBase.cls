public with sharing virtual class GitCommit_ComponentBase {

    public GitCommit_PageBase pageController {
        get;
        set {
            if(value != null) {
                pageController = value;
                pageController.setComponentController(this);
            }
        }
    }

    // Constant
    public final String C_DONE = 'done';
    public final String C_ERROR = 'error';
    public final String C_WARNING = 'warning';
    public final String C_INFO = 'info';
    public final String C_SUCCESS = 'success';


    /**
     * It is used to count messages size in the list, so at the component it will be used to render messages
     *
     * @return
     */
    public Integer getPageMessageSize() {
        Integer listsize = 0;
        for(String severity : pageController.pageMessagesMap.keySet()) {
            listsize += pageController.pageMessagesMap.get(severity).size();
        }
        return listsize;
    }
}