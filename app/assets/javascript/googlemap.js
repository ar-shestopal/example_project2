$(window).load(function(){
  setTimeout(function(){ $('.loadtext').fadeOut() }, 10000);
});

var map;
//var apiKey = 'AIzaSyAEqKwQ8hYEXzsg-fXYoaKd8ifgS0Vl5sM';
//var tableID = '1ksvdEvNC-dpmIELLJSqIAOlxHBSz04JYYt0mYKRl';
//var latitudeColumn = 'lat';
//var longitudeColumn = 'lng';

function fetchData() {

  // Construct the query to the Fusion Table
  //var query = 'SELECT ' + latitudeColumn + ','
              //+ longitudeColumn + ' FROM '
              //+ tableID;
  //var encodedQuery = encodeURIComponent(query);

  // Construct the URL
  //var url = ['https://www.googleapis.com/fusiontables/v1/query'];
      //url.push('?sql=' + encodedQuery);
      //url.push('&key=' + apiKey);
      //url.push('&callback=?');

  // Send the JSONP request using jQuery
    $.ajax({
      url: '/coordinates',
      dataType: 'json',
      success: onDataFetched
    });
}

function onDataFetched(data) {
  var heatmapData = [];
  var i;
  for (i = 0; i < data.length; i += 1){
    var lat = data[i].latitude;
    var lng = data[i].longitude;
    heatmapData.push(new google.maps.LatLng(lat,lng));
  }
  var heatmap = new google.maps.visualization.HeatmapLayer({
      data: heatmapData,
      dissipating: true,
      maxIntensity: 1,
      radius: 16
  });
  heatmap.setMap(map);

}

function initialize() {
fetchData();

    var markers = [];
    map = new google.maps.Map(document.getElementById('map-canvas'), {
        scrollwheel: false,
        minZoom: 5,
        maxZoom: 13,        
        mapTypeId: google.maps.MapTypeId.ROADMAP
    });

    $('#crowdgps_modal').on('shown.bs.modal', function () {
      google.maps.event.trigger(map, 'resize');
      map.setCenter(new google.maps.LatLng(39.828127, -98.579404));
    });

    var defaultBounds = new google.maps.LatLngBounds(
        new google.maps.LatLng(39.828127, -98.579404));
    map.fitBounds(defaultBounds);
    var listener = google.maps.event.addListener(map, "idle", function() {
        if (map.getZoom() > 1) map.setZoom(1);
        google.maps.event.removeListener(listener);
    });

    // Create the search box and link it to the UI element.
    var input = /** @type {HTMLInputElement} */ (
        document.getElementById('pac-input'));
    map.controls[google.maps.ControlPosition.TOP_LEFT].push(input);

    var searchBox = new google.maps.places.SearchBox(
        /** @type {HTMLInputElement} */
        (input));

    // [START region_getplaces]
    // Listen for the event fired when the user selects an item from the
    // pick list. Retrieve the matching places for that item.
    google.maps.event.addListener(searchBox, 'places_changed', function() {
        var places = searchBox.getPlaces();

        if (places.length == 0) {
            return;
        }
        for (var i = 0, marker; marker = markers[i]; i++) {
            marker.setMap(null);
        }

        // For each place, get the icon, place name, and location.
        markers = [];
        var bounds = new google.maps.LatLngBounds();
        for (var i = 0, place; place = places[i]; i++) {
            var image = {
                url: place.icon,
                size: new google.maps.Size(71, 71),
                origin: new google.maps.Point(0, 0),
                anchor: new google.maps.Point(17, 34),
                scaledSize: new google.maps.Size(25, 25)
            };

            // Create a marker for each place.
            var marker = new google.maps.Marker({
                map: map,
                icon: image,
                title: place.name,
                position: place.geometry.location
            });

            markers.push(marker);

            bounds.extend(place.geometry.location);
        }

        map.fitBounds(bounds);
    });
    // [END region_getplaces]

    // Bias the SearchBox results towards places that are within the bounds of the
    // current map's viewport.
    google.maps.event.addListener(map, 'bounds_changed', function() {
        var bounds = map.getBounds();
        searchBox.setBounds(bounds);
    });
}

google.maps.event.addDomListener(window, 'load', initialize);
