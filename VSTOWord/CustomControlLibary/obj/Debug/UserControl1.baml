   M S B A M L   `   `   `  ����Q  MFlickrNet, Version=3.15.0.0, Culture=neutral, PublicKeyToken=2491df59efa5d1328*clr-namespace:FlickrNet;assembly=FlickrNet	FlickrNet  5       CustomControlLibary&    CustomControlLibary.UserControl1   5      \ XPresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35R NWindowsBase, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35W SPresentationCore, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35D 9http://schemas.microsoft.com/winfx/2006/xaml/presentation    5      R NSystem.Xaml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5      Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5      @d2http://schemas.microsoft.com/expression/blend/2008     5      @	flickrNet*clr-namespace:FlickrNet;assembly=FlickrNet     5      .��5	      �   � RowDefinitions  5
   
   �� 5      $
��Auto �6   �� 5      $��* �6   �� 5      $
��AUto �6   .+�5   
   ��  �� Orientation$ 
Horizontal=�6   .+�5      �� -   5         ��Name$ textBox��5      $��10q�6'   $��23��63    �� TextWrapping$
 Wrap=�6@   $
��food��6T   $	��Top=�6`   $	��120��6x   �� 5      -   5        $	��Get��5      $��10q�6#   $	��Top=�6/   $��76��6G   6R   5      �� 5   
   -   5         ��Name$
 list��5      $��1��6    ��5      �� 5       �� DataType$ flickrNet:Photo��6   .R�5      �� $ Vertical=�6!   .+�5      �� ��6!   �� *	Command+.��5      �� ��6$   �� *ThumbnailUrl+5      �� 5      ��6$   �� *Title+5      5      5      �� 5   
   $��2��6   $ 
Horizontal=�6"   .+�5       �� -   5         ��Name$ 
statusText��5       $��Center=�6,   $
��Wrap=�6J   $	��Top=�6^   5!      5#      5$      