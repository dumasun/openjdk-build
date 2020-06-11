class Config8 {
  final Map<String, Map<String, ?>> buildConfigurations = [
        mips64        : [
                os                  : 'linux',
                arch                : 'mips64',
                additionalNodeLabels: [
                        hotspot : 'x86-i7-250'
                ],
                test                : ['sanity.openjdk', 'sanity.system', 'extended.system', 'special.openjdk']
        ],
  ]

}

Config8 config = new Config8()
return config.buildConfigurations
