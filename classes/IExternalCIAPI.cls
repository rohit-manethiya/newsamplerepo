/**
 * This is an interface for External CI API
 * Manages requests to the CI system and parsing it's response body
 * @author Mert YALTI
 * @date 16.06.2017
 */
public interface IExternalCIAPI {
	/**
	 * Generic http request method
	 * @return HttpResponse
	 */
	HttpResponse sendRequestToCI(String endPoint, String method, Map<String,String> optionalHeaders, Boolean isInternal);
	/**
	 * Generic parse method
	 * @return any type
	 */
	Object parseResponseBody(String type, HttpResponse response);
}