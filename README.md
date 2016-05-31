# Entry CSV Export plugin for Movable Type

A plugin for Movable Type installations which provides a very basic
export-to-CSV functionality for entries/pages to facilitate easier review of
entry/page metadata.

* Enables full-fidelity export of entry/page data in CSV format for those
  entries/pages selected from the listing screen.
* Export selected Entries/Pages or all Entries/Pages in a given blog, or
  system-wide.

## Prerequisites

* Movable Type 6.1+
* Movable Type v4.3x, 5.x, 6.0.x are supported with version
  [1.0.3](https://github.com/endevver/mt-plugin-entry-csvexport/releases/tag/v1.0.3).

## Installation

Unzip the download archive. Move the resulting folder to `$MT_HOME/plugins/`
(where `$MT_HOME` is your MT or Melody application directory).

If you use Git, you can do the following:

    cd $MT_HOME/plugins
    git clone git@github.com:endevver/mt-plugin-entry-csvexport.git

## Configuration

There is no configuration for this plugin.

## Use

At the blog, website, or system level visit Manage > Entries or Manage > Pages.

Export selected Entries/Pages by placing checkmarks next to the items to
export, then from the "More actions…" drop down select "Export as CSV" then
click "Go."

To export all Entries/Pages, click the checkbox in the listing header, which
will select all visible objects. A new row in the listing table will appear:
click "Select all xxx items," then choose "Export as CSV" from the "More
actions..." drop down and click "Go." Users of Movable Type 4.3x: choose "Export
this blog's entries (CSV)" from the Actions topic in the sidebar.

Depending upon the amount of data to export it could take a few minutes until
you are able to begin downloading the CSV file.

## Help, Bugs, and Feature Requests

If you are having problems installing or using the plugin, please check out our
general knowledge base and help ticket system at
[help.endevver.com](http://help.endevver.com).

If you know that you've encountered a bug in the plugin or you have a request
for a feature you'd like to see, you can file a ticket in [Github
Issues](https://github.com/endevver/mt-plugin-entry-csvexport/issues).

## COPYRIGHT ##

Copyright 2012, Endevver, LLC.  All rights reserved.

## LICENSE ##

This plugin is licensed under the same terms as Perl itself.

## ABOUT ENDEVVER ##

We design and develop web sites, products and services with a focus on 
simplicity, sound design, ease of use and community. We specialize in 
Movable Type and offer numerous services and packages to help customers 
make the most of this powerful publishing platform.

http://www.endevver.com/
