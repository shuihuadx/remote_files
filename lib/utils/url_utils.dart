class UrlUtils {
  static String getUrlLastPath(String url) {
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    int flag = url.lastIndexOf('/');
    if (flag < 0) {
      return url;
    } else {
      return url.substring(flag + 1);
    }
  }
}
