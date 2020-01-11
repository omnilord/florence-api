function simpleMap(options) {
  var center = [ options.lng, options.lat ],
      map = new mapboxgl.Map({
        container: document.querySelector(options.selector),
        // style: 'mapbox://styles/miklb-c4tb/cjnozdzs41qlx2rqvf7mwfztt',
        style: 'mapbox://styles/mapbox/streets-v11',
        center: center,
        zoom: 13.5
      }),
      el = document.createElement('div');

  el.className = 'marker';
  new mapboxgl.Marker(el)
    .setLngLat(center)
    .addTo(map);
}
