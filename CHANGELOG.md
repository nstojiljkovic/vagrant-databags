# vagrant-databags Changelog

## 0.1.4

Fix hook execution order on vagrant 2.1.3 (and higher) with vagrant-managed-servers plugin installed.

## 0.1.3

Fix hook execution order on vagrant 2.1.3 (and higher) with vagrant-lifecycle plugin installed.

## 0.1.2

Bug fixes:

* properly evaluate data bags folder when passed as an absolute path
* respect `cleanup_on_provision` setting when performing recover on failed vagrant command

## 0.1.1

Changed event hooks in order to make the plugin compatible with othe plugins such as [vagrant-managed-servers](https://github.com/tknerr/vagrant-managed-servers).

## 0.1.0

Initial release.
