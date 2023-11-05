import '../hko_types.dart';

class DummyTyphoon extends Typhoon {
  DummyTyphoon(
      {required super.id,
      required super.chineseName,
      required super.englishName,
      required super.url});

  @override
  Future<TyphoonTrack?> getTyphoonTrack() {
    return dummyTrack();
  }
}

Typhoon dummyTyphoon() {
  return DummyTyphoon(
      id: 2102,
      chineseName: '舒力基',
      englishName: 'SURIGAE',
      url: 'http://www.weather.gov.hk/wxinfo/currwx/hko_tctrack_2102.xml');
}

Future<TyphoonTrack?> dummyTrack() async {
  String fileContents = """
    <?xml version="1.0" encoding="UTF-8"?>
<TropicalCycloneTrack xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" tcid="2102"
    xsi:noNamespaceSchemaLocation="tc_track.xsd">
    <BulletinHeader>
        <BulletinName>Tropical Cyclone Track</BulletinName>
        <BulletinType>R</BulletinType>
        <BulletinProvider>Hong Kong Observatory</BulletinProvider>
        <BulletinTime>2021-04-25T13:00:10+08:00</BulletinTime>
        <Copyright>The content available in this file, including but not limited to all text,
            graphics, drawings, diagrams, photographs and compilation of data or other materials are
            protected by copyright. The Government of the Hong Kong Special Administrative Region is
            the owner of all copyright works contained in this website. Any reproduction,
            adaptation, distribution, dissemination or making available of such copyright works to
            the public is strictly prohibited unless prior written authorization is obtained from
            the Hong Kong Observatory.
        </Copyright>
        <Disclaimer>The Government of the Hong Kong Special Administrative Region (including its
            servants and agents) makes no warranty, statement or representation, express or implied,
            with respect to the accuracy, availability, completeness or usefulness of the
            information, contained herein, and in so far as permitted by law, shall not have any
            legal liability or responsibility (including liability for negligence) for any loss,
            damage, or injury (including death) which may result, whether directly or indirectly,
            from the supply or use of such information.
        </Disclaimer>
        <Remarks>You are welcome to write to the Hong Kong Observatory for authorization to make
            available information on this file to the public. For enquires, please contact the Hong
            Kong Observatory by e-mail (mailbox@hko.gov.hk) or fax (2311 9448).
        </Remarks>
    </BulletinHeader>
    <WeatherReport>
        <TropicalCycloneName>SURIGAE</TropicalCycloneName>
        <PastInformation>
            <Index>1</Index>
            <Intensity>Tropical Depression</Intensity>
            <MaximumWind>45km/h</MaximumWind>
            <Time>2021-04-13T12:00:00+00:00</Time>
            <Latitude>7.40N</Latitude>
            <Longitude>138.00E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>2</Index>
            <Intensity>Tropical Depression</Intensity>
            <MaximumWind>55km/h</MaximumWind>
            <Time>2021-04-13T18:00:00+00:00</Time>
            <Latitude>7.70N</Latitude>
            <Longitude>137.60E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>3</Index>
            <Intensity>Tropical Storm</Intensity>
            <MaximumWind>65km/h</MaximumWind>
            <Time>2021-04-14T00:00:00+00:00</Time>
            <Latitude>8.10N</Latitude>
            <Longitude>137.60E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>4</Index>
            <Intensity>Tropical Storm</Intensity>
            <MaximumWind>65km/h</MaximumWind>
            <Time>2021-04-14T06:00:00+00:00</Time>
            <Latitude>8.40N</Latitude>
            <Longitude>137.50E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>5</Index>
            <Intensity>Tropical Storm</Intensity>
            <MaximumWind>85km/h</MaximumWind>
            <Time>2021-04-14T12:00:00+00:00</Time>
            <Latitude>8.80N</Latitude>
            <Longitude>137.00E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>6</Index>
            <Intensity>Tropical Storm</Intensity>
            <MaximumWind>85km/h</MaximumWind>
            <Time>2021-04-14T18:00:00+00:00</Time>
            <Latitude>8.90N</Latitude>
            <Longitude>136.70E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>7</Index>
            <Intensity>Severe Tropical Storm</Intensity>
            <MaximumWind>90km/h</MaximumWind>
            <Time>2021-04-15T00:00:00+00:00</Time>
            <Latitude>8.80N</Latitude>
            <Longitude>136.30E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>8</Index>
            <Intensity>Severe Tropical Storm</Intensity>
            <MaximumWind>90km/h</MaximumWind>
            <Time>2021-04-15T06:00:00+00:00</Time>
            <Latitude>8.80N</Latitude>
            <Longitude>136.00E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>9</Index>
            <Intensity>Severe Tropical Storm</Intensity>
            <MaximumWind>105km/h</MaximumWind>
            <Time>2021-04-15T12:00:00+00:00</Time>
            <Latitude>8.90N</Latitude>
            <Longitude>135.60E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>10</Index>
            <Intensity>Severe Tropical Storm</Intensity>
            <MaximumWind>110km/h</MaximumWind>
            <Time>2021-04-15T18:00:00+00:00</Time>
            <Latitude>8.90N</Latitude>
            <Longitude>135.30E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>11</Index>
            <Intensity>Typhoon</Intensity>
            <MaximumWind>120km/h</MaximumWind>
            <Time>2021-04-16T00:00:00+00:00</Time>
            <Latitude>8.90N</Latitude>
            <Longitude>134.70E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>12</Index>
            <Intensity>Typhoon</Intensity>
            <MaximumWind>130km/h</MaximumWind>
            <Time>2021-04-16T06:00:00+00:00</Time>
            <Latitude>9.10N</Latitude>
            <Longitude>133.70E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>13</Index>
            <Intensity>Typhoon</Intensity>
            <MaximumWind>140km/h</MaximumWind>
            <Time>2021-04-16T12:00:00+00:00</Time>
            <Latitude>9.30N</Latitude>
            <Longitude>133.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>14</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>165km/h</MaximumWind>
            <Time>2021-04-16T18:00:00+00:00</Time>
            <Latitude>10.00N</Latitude>
            <Longitude>132.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>15</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>195km/h</MaximumWind>
            <Time>2021-04-17T00:00:00+00:00</Time>
            <Latitude>10.70N</Latitude>
            <Longitude>131.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>16</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>220km/h</MaximumWind>
            <Time>2021-04-17T06:00:00+00:00</Time>
            <Latitude>11.30N</Latitude>
            <Longitude>130.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>17</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>240km/h</MaximumWind>
            <Time>2021-04-17T12:00:00+00:00</Time>
            <Latitude>12.00N</Latitude>
            <Longitude>129.20E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>18</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>240km/h</MaximumWind>
            <Time>2021-04-17T18:00:00+00:00</Time>
            <Latitude>12.50N</Latitude>
            <Longitude>128.40E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>19</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>240km/h</MaximumWind>
            <Time>2021-04-18T00:00:00+00:00</Time>
            <Latitude>13.10N</Latitude>
            <Longitude>127.70E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>20</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>240km/h</MaximumWind>
            <Time>2021-04-18T06:00:00+00:00</Time>
            <Latitude>13.50N</Latitude>
            <Longitude>127.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>21</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>240km/h</MaximumWind>
            <Time>2021-04-18T12:00:00+00:00</Time>
            <Latitude>13.50N</Latitude>
            <Longitude>126.80E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>22</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>240km/h</MaximumWind>
            <Time>2021-04-18T18:00:00+00:00</Time>
            <Latitude>14.00N</Latitude>
            <Longitude>126.50E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>23</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>230km/h</MaximumWind>
            <Time>2021-04-19T00:00:00+00:00</Time>
            <Latitude>14.20N</Latitude>
            <Longitude>126.30E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>24</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>230km/h</MaximumWind>
            <Time>2021-04-19T06:00:00+00:00</Time>
            <Latitude>14.50N</Latitude>
            <Longitude>126.30E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>25</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>210km/h</MaximumWind>
            <Time>2021-04-19T12:00:00+00:00</Time>
            <Latitude>14.80N</Latitude>
            <Longitude>126.30E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>26</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>205km/h</MaximumWind>
            <Time>2021-04-19T18:00:00+00:00</Time>
            <Latitude>15.20N</Latitude>
            <Longitude>126.30E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>27</Index>
            <Intensity>Super Typhoon</Intensity>
            <MaximumWind>195km/h</MaximumWind>
            <Time>2021-04-20T00:00:00+00:00</Time>
            <Latitude>15.60N</Latitude>
            <Longitude>126.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>28</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>175km/h</MaximumWind>
            <Time>2021-04-20T06:00:00+00:00</Time>
            <Latitude>15.80N</Latitude>
            <Longitude>125.90E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>29</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>175km/h</MaximumWind>
            <Time>2021-04-20T12:00:00+00:00</Time>
            <Latitude>16.40N</Latitude>
            <Longitude>125.90E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>30</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>175km/h</MaximumWind>
            <Time>2021-04-20T18:00:00+00:00</Time>
            <Latitude>16.90N</Latitude>
            <Longitude>125.40E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>31</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>175km/h</MaximumWind>
            <Time>2021-04-21T00:00:00+00:00</Time>
            <Latitude>17.50N</Latitude>
            <Longitude>125.20E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>32</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>175km/h</MaximumWind>
            <Time>2021-04-21T03:00:00+00:00</Time>
            <Latitude>17.80N</Latitude>
            <Longitude>125.00E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>33</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>165km/h</MaximumWind>
            <Time>2021-04-21T06:00:00+00:00</Time>
            <Latitude>18.10N</Latitude>
            <Longitude>124.90E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>34</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>165km/h</MaximumWind>
            <Time>2021-04-21T09:00:00+00:00</Time>
            <Latitude>18.60N</Latitude>
            <Longitude>124.80E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>35</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>165km/h</MaximumWind>
            <Time>2021-04-21T12:00:00+00:00</Time>
            <Latitude>18.80N</Latitude>
            <Longitude>124.80E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>36</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>165km/h</MaximumWind>
            <Time>2021-04-21T15:00:00+00:00</Time>
            <Latitude>19.00N</Latitude>
            <Longitude>124.80E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>37</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>155km/h</MaximumWind>
            <Time>2021-04-21T18:00:00+00:00</Time>
            <Latitude>19.30N</Latitude>
            <Longitude>124.70E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>38</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>155km/h</MaximumWind>
            <Time>2021-04-21T21:00:00+00:00</Time>
            <Latitude>19.50N</Latitude>
            <Longitude>124.80E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>39</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>155km/h</MaximumWind>
            <Time>2021-04-22T00:00:00+00:00</Time>
            <Latitude>19.70N</Latitude>
            <Longitude>124.90E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>40</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>155km/h</MaximumWind>
            <Time>2021-04-22T03:00:00+00:00</Time>
            <Latitude>20.00N</Latitude>
            <Longitude>125.00E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>41</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>155km/h</MaximumWind>
            <Time>2021-04-22T06:00:00+00:00</Time>
            <Latitude>20.30N</Latitude>
            <Longitude>125.40E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>42</Index>
            <Intensity>Severe Typhoon</Intensity>
            <MaximumWind>155km/h</MaximumWind>
            <Time>2021-04-22T09:00:00+00:00</Time>
            <Latitude>20.50N</Latitude>
            <Longitude>125.80E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>43</Index>
            <Intensity>Typhoon</Intensity>
            <MaximumWind>145km/h</MaximumWind>
            <Time>2021-04-22T12:00:00+00:00</Time>
            <Latitude>21.00N</Latitude>
            <Longitude>126.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>44</Index>
            <Intensity>Typhoon</Intensity>
            <MaximumWind>140km/h</MaximumWind>
            <Time>2021-04-22T18:00:00+00:00</Time>
            <Latitude>21.60N</Latitude>
            <Longitude>127.00E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>45</Index>
            <Intensity>Typhoon</Intensity>
            <MaximumWind>130km/h</MaximumWind>
            <Time>2021-04-23T00:00:00+00:00</Time>
            <Latitude>22.40N</Latitude>
            <Longitude>127.80E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>46</Index>
            <Intensity>Typhoon</Intensity>
            <MaximumWind>120km/h</MaximumWind>
            <Time>2021-04-23T06:00:00+00:00</Time>
            <Latitude>23.10N</Latitude>
            <Longitude>129.00E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>47</Index>
            <Intensity>Severe Tropical Storm</Intensity>
            <MaximumWind>110km/h</MaximumWind>
            <Time>2021-04-23T09:00:00+00:00</Time>
            <Latitude>23.30N</Latitude>
            <Longitude>129.40E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>48</Index>
            <Intensity>Severe Tropical Storm</Intensity>
            <MaximumWind>110km/h</MaximumWind>
            <Time>2021-04-23T12:00:00+00:00</Time>
            <Latitude>23.40N</Latitude>
            <Longitude>129.90E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>49</Index>
            <Intensity>Severe Tropical Storm</Intensity>
            <MaximumWind>105km/h</MaximumWind>
            <Time>2021-04-23T18:00:00+00:00</Time>
            <Latitude>23.40N</Latitude>
            <Longitude>130.40E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>50</Index>
            <Intensity>Severe Tropical Storm</Intensity>
            <MaximumWind>90km/h</MaximumWind>
            <Time>2021-04-24T00:00:00+00:00</Time>
            <Latitude>23.10N</Latitude>
            <Longitude>131.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>51</Index>
            <Intensity>Tropical Storm</Intensity>
            <MaximumWind>85km/h</MaximumWind>
            <Time>2021-04-24T06:00:00+00:00</Time>
            <Latitude>22.80N</Latitude>
            <Longitude>131.90E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>52</Index>
            <Intensity>Tropical Storm</Intensity>
            <MaximumWind>85km/h</MaximumWind>
            <Time>2021-04-24T12:00:00+00:00</Time>
            <Latitude>22.20N</Latitude>
            <Longitude>132.80E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>53</Index>
            <Intensity>Tropical Storm</Intensity>
            <MaximumWind>75km/h</MaximumWind>
            <Time>2021-04-24T18:00:00+00:00</Time>
            <Latitude>21.90N</Latitude>
            <Longitude>134.10E</Longitude>
        </PastInformation>
        <PastInformation>
            <Index>54</Index>
            <Intensity>Tropical Storm</Intensity>
            <MaximumWind>65km/h</MaximumWind>
            <Time>2021-04-25T00:00:00+00:00</Time>
            <Latitude>21.80N</Latitude>
            <Longitude>135.80E</Longitude>
        </PastInformation>
        <AnalysisInformation>
            <Intensity>Extratropical Low</Intensity>
            <MaximumWind>--</MaximumWind>
            <Time>2021-04-25T03:00:00+00:00</Time>
            <Latitude>21.90N</Latitude>
            <Longitude>136.80E</Longitude>
        </AnalysisInformation>
    </WeatherReport>
</TropicalCycloneTrack>
    """;
  TyphoonTrack? typhoonTrack = parseTyphoonTrack(fileContents);
  return typhoonTrack;
}
