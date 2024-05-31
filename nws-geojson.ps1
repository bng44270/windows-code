########################
#
# Dump-NwsStationGeoJson
#
# Dump GeoJSON containing location and information for National Weather Service Stations
#
# Usage:
#    Dump-NwsStationGeoJson -Out ./nws-stations.json
#
########################
function Dump-NwsStationGeoJson($Out) {
  if (-not $Out) {
    echo "usage: Dump-NwsStationGeoJson -Out <output-file>"
  }
  else {
    $resp = (Invoke-WebRequest -AllowInsecureRedirect "https://weather.gov/xml/current_obs/index.xml")
    
    $stationXml = [xml]$resp.Content
    
    $stationFeaturesJson = ($stationXml.wx_station_index.station | ForEach-Object {
      [pscustomobject]@{
        type = "Feature"
        geometry = ([pscustomobject]@{
          type = "Point"
          coordinates = @([double]::Parse($_.longitude), [double]::Parse($_.latitude))
        })
        properties = ([pscustomobject]@{
          id = $_.station_id
          state = $_.state
          name = $_.station_name
          obs = $_.xml_url
        })
      }
    })

    ([pscustomobject]@{
      type = "FeatureCollection"
      features = $stationFeaturesJson
    }) | convertto-json -depth 4 | Out-File -FilePath $Out
  }
}
