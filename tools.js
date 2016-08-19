(function(){

  // Move code samples to where they belong
  var placeholders = document.getElementsByClassName("placeholder");
  var samples = document.getElementsByClassName("sample");
  for(var i=0; i < placeholders.length; i++) {
    placeholders[i].appendChild(samples[i]);
  }

  // Retrieve several tags at once
  function getElementsByTagNames(list,obj) {
  	if (!obj) var obj = document;
  	var tagNames = list.split(',');
  	var resultArray = new Array();
  	for (var i=0;i<tagNames.length;i++) {
  		var tags = obj.getElementsByTagName(tagNames[i]);
  		for (var j=0;j<tags.length;j++) {
  			resultArray.push(tags[j]);
  		}
  	}
  	var testNode = resultArray[0];
  	if (!testNode) return [];
  	if (testNode.sourceIndex) {
  		resultArray.sort(function (a,b) {
  				return a.sourceIndex - b.sourceIndex;
  		});
  	}
  	else if (testNode.compareDocumentPosition) {
  		resultArray.sort(function (a,b) {
  				return 3 - (a.compareDocumentPosition(b) & 6);
  		});
  	}
  	return resultArray;
  }

  // Create table of content
  var y = document.getElementById('TOC');
  if(y) {
    var z = y.appendChild(document.createElement('div'));
    var toBeTOCced = getElementsByTagNames('h2,h3');
    for (var i=0;i<toBeTOCced.length;i++) {
    	var tmp = document.createElement('a');
    	tmp.innerHTML = toBeTOCced[i].innerHTML;
      var p = document.createElement('p');
      p.className = 'toc-'+toBeTOCced[i].nodeName;
      p.appendChild(tmp);
    	z.appendChild(p);
    	var headerId = toBeTOCced[i].id || 'link' + i;
    	tmp.href = '#' + headerId;
    	toBeTOCced[i].id = headerId;
    }
  }

  // Replace hybind@latest with actual version
  var xhttp = new XMLHttpRequest();
  xhttp.open("GET", "http://cors.maxogden.com/https://registry.npmjs.org/-/package/hybind/dist-tags", true);
  xhttp.onreadystatechange = function() {
    if (xhttp.readyState == 4 && xhttp.status == 200) {
      var version = JSON.parse(xhttp.responseText).latest;
      var tags = document.getElementsByClassName('atv');
      for (var i = 0; i < tags.length; ++i) {
        var item = tags[i];
        item.innerHTML = item.innerHTML.replace(/hybind@latest/, "hybind@"+version);
      }
    }
  };
  xhttp.send();
})();
