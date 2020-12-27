<!--
  WARNING
    you MUST escape curly braces (duplicate them) in attribute values to
    prevent them to be evaluated as XPath expressions.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes"/>
  <xsl:template match="Category[@name='Environment_FontsAndColors']/FontsAndColors">
    <FontsAndColors Version="2.0">
      <!--
          Theme                 Id
          ===================== ======================================
          Blue                  {A4D6A176-B948-4B29-8C66-53C97A1ED7D0}
          Blue (Extra Contrast) {CE94D289-8481-498B-8CA9-9B6191A315B9}
          Dark                  {1DED0138-47CE-435E-84EF-9EC1F439B749}
          Light                 {DE3DBBCD-F642-433C-8353-8F1DF4370ABA}
      -->
      <Theme Id="{{1DED0138-47CE-435E-84EF-9EC1F439B749}}"/>
      <Categories>
        <Category GUID="{{75A05685-00A8-4DED-BAE5-E7A50BFA929A}}" FontName="DejaVuSansMono NF" FontSize="11" CharSet="1" FontIsDefault="No"/>
        <Category GUID="{{FF349800-EA43-46C1-8C98-878E78F46501}}" FontName="DejaVuSansMono NF" FontSize="11" CharSet="1" FontIsDefault="No"/>
        <Category GUID="{{E0187991-B458-4F7E-8CA9-42C9A573B56C}}" FontName="DejaVuSansMono NF" FontSize="11" CharSet="1" FontIsDefault="No"/>
        <Category GUID="{{58E96763-1D3B-4E05-B6BA-FF7115FD0B7B}}" FontName="DejaVuSansMono NF" FontSize="11" CharSet="1" FontIsDefault="No"/>
      </Categories>
    </FontsAndColors>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
