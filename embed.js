responseIndex = 0;
http = hybind.http = function(opts) {
  var req = opts.method + " http://localhost:8080/" + opts.url + " HTTP/1.1\n"
  $.each(opts.headers, function (k, v) {
  	req += k+": "+v+"\n";
  });
  if(opts.data) {
  	req += "\n" + JSON.stringify(JSON.parse(opts.data), null, 2);
  }
	var elt = $("<code/>").addClass("http").text(req);
  $("body").append($("<pre/>").append(elt));
  hljs.highlightBlock(elt.get(0));
  return $.Deferred().resolve(responses[responseIndex++]).promise();
}

var originalConsole = window.console;
window.console = {
  log: function(x) {
    originalConsole.log(x);
    var name = "";
    $.each(window, function(k, v) {
      if(v === x) {
      	name = k+" = "
      }
    });
    var elt = $("<code/>").addClass("javascript").text(name + stringify(JSON.parse(JSON.stringify(x))));
    $("body").append($("<pre/>").append(elt));
    hljs.highlightBlock(elt.get(0));
	}
}
